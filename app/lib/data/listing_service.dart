import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../core/image_analysis_service.dart';
import 'package:hive/hive.dart';

class ListingService {
  ListingService() {
    _syncDriver = this;
    _initializeOnce();
  }

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _collection = 'listings';
  final ImageAnalysisService _imageAnalysisService = CloudVisionImageAnalysisService();

  static const String _pendingOpsStorageKey = 'listing_pending_operations_v1';
  static const String _typeCreate = 'pending_create';
  static const String _typeUpdate = 'pending_update';
  static const String _typeDelete = 'pending_delete';
  static const int _maxAiTagImages = 3;

  static bool _initialized = false;
  static bool _syncInProgress = false;
  static StreamSubscription<dynamic>? _connectivitySub;
  static ListingService? _syncDriver;

  void _initializeOnce() {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub = Connectivity().onConnectivityChanged.listen((event) {
      if (_hasConnectivity(event)) {
        unawaited(_syncDriver?._syncPendingOperations());
      }
    });

    unawaited(_syncPendingOperations());
  }

  /// Returns the DateTime of the last post (listing) by this seller, or null if none.
  Future<DateTime?> getLastPostDate(String sellerId) async {
    final query = await _db
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final listing = Listing.fromFirestore(query.docs.first);
    return listing.createdAt;
  }

  // Almacena los listados en Hive
  Future<void> _cacheListings(List<Listing> listings) async {
    final box = await Hive.openBox<List>('listings_cache');
    await box.put('cached_listings', listings.map((listing) => listing.toJson()).toList());
    debugPrint('Cached ${listings.length} listings in Hive.');
  }

  // Recupera los listados desde Hive
  Future<List<Listing>> _getCachedListings() async {
    final box = await Hive.openBox<List>('listings_cache');
    final cachedData = box.get('cached_listings', defaultValue: []) ?? [];
    return cachedData.map<Listing>((json) => Listing.fromJson(json)).toList();
  }

  Stream<List<Listing>> getListings() async* {
    final isOnline = await _isOnline();
    debugPrint('Checking online status: $isOnline');

    if (isOnline) {
      debugPrint('Fetching listings from Firebase...');
      yield* _db
          .collection(_collection)
          .snapshots()
          .asyncMap((snapshot) async {
            debugPrint('Firebase snapshot received with ${snapshot.docs.length} documents.');
            final listings = snapshot.docs.map((doc) {
              debugPrint('Document data: ${doc.data()}');
              return Listing.fromFirestore(doc);
            }).toList();

            listings.sort((a, b) {
              final aCreated = a.createdAt;
              final bCreated = b.createdAt;
              if (aCreated == null && bCreated == null) return 0;
              if (aCreated == null) return 1;
              if (bCreated == null) return -1;
              return bCreated.compareTo(aCreated);
            });

            await _cacheListings(listings); // Almacenar en Hive
            debugPrint('Listings cached in Hive.');
            return listings;
          });
    } else {
      debugPrint('Offline mode: Fetching cached listings from Hive...');
      final cachedListings = await _getCachedListings();
      debugPrint('Cached listings retrieved: ${cachedListings.length} items.');
      yield cachedListings;
    }
  }

  Stream<List<Listing>> getListingsBySellerId(String sellerId) {
    return _db
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final listings =
              snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();
          listings.sort((a, b) {
            final aCreated = a.createdAt;
            final bCreated = b.createdAt;
            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;
            return bCreated.compareTo(aCreated);
          });
          return listings;
        });
  }

  Future<Listing?> getListingById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Listing.fromFirestore(doc);
  }

  Future<void> syncPendingOperations() async {
    await _syncPendingOperations();
  }

  Future<bool> isOnlineNow() async {
    return _isOnline();
  }

  Future<String> _uploadImage(XFile image, String listingId, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final bytes = await image.readAsBytes();
    final ext = _normalizeExtension(image.name);
    final fileName = _buildUniqueFileName(index, ext);
    final ref = _storage.ref().child('listings/${user.uid}/$listingId/$fileName');
    final contentType = _contentTypeForExtension(ext);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {
        'originalFileName': image.name,
        'originalExtension': ext,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    debugPrint(
      '[ListingService] upload start name=${image.name} size=${bytes.length} ext=$ext contentType=$contentType path=${ref.fullPath}',
    );

    await ref.putData(bytes, metadata);
    final downloadUrl = await ref.getDownloadURL();
    debugPrint('[ListingService] upload done url=$downloadUrl');
    return downloadUrl;
  }

  Future<Listing> createListing({
    required Listing listing,
    required List<XFile> images,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final shouldQueuePendingTags = listing.tags.isEmpty && images.isNotEmpty;
    final isOnline = await _isOnline();

    if (!isOnline) {
      final localId = _localListingId();
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeCreate,
        'listingId': localId,
        'sellerId': user?.uid ?? 'unknown_user',
        'listing': _serializeListingForQueue(listing, sellerId: user?.uid ?? 'unknown_user'),
        'imagePaths': images.map((e) => e.path).where((e) => e.trim().isNotEmpty).toList(),
        'pendingTags': shouldQueuePendingTags,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });

      return _cloneListingWith(
        listing,
        id: localId,
        sellerId: user?.uid ?? 'unknown_user',
        createdAt: DateTime.now(),
      );
    }

    try {
      return await _createListingOnline(
        listing: listing,
        images: images,
        sellerId: user?.uid ?? 'unknown_user',
      );
    } catch (e) {
      debugPrint('[ListingService] createListing online failed, queueing offline: $e');
      final localId = _localListingId();
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeCreate,
        'listingId': localId,
        'sellerId': user?.uid ?? 'unknown_user',
        'listing': _serializeListingForQueue(listing, sellerId: user?.uid ?? 'unknown_user'),
        'imagePaths': images.map((e) => e.path).where((e) => e.trim().isNotEmpty).toList(),
        'pendingTags': shouldQueuePendingTags,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });

      return _cloneListingWith(
        listing,
        id: localId,
        sellerId: user?.uid ?? 'unknown_user',
        createdAt: DateTime.now(),
      );
    }
  }

  Future<Listing> _createListingOnline({
    required Listing listing,
    required List<XFile> images,
    required String sellerId,
  }) async {
    final docRef = _db.collection(_collection).doc();
    final listingId = docRef.id;
    List<String> imageUrls = [];
    for (int i = 0; i < images.length && i < 5; i++) {
      final url = await _uploadImage(images[i], listingId, i);
      imageUrls.add(url);
    }
    final data = listing.toFirestore()
      ..addAll({
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
        'imageURLs': imageUrls,
        'imagePath': imageUrls.isNotEmpty ? imageUrls[0] : '',
      });
    await docRef.set(data);

    // Analytics: track new item uploaded
    final category = (listing.tags.isNotEmpty ? listing.tags[0] : 'Other');
    AnalyticsService.instance.track(
      AnalyticsEvent.newItemUploaded(
        userId: sellerId,
        category: category,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    if (listing.tags.contains('IA_TAGGING')) {
      AnalyticsService.instance.track(
        AnalyticsEvent.listingCreatedWithIATagging(
          listingId: listing.id,
          userId: user?.uid ?? 'unknown_user',
        ),
      );
    }

    final doc = await docRef.get();
    return Listing.fromFirestore(doc);
  }

  Future<void> updateListing(Listing listing) async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeUpdate,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'listing': _serializeListingForQueue(listing, sellerId: listing.sellerId),
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }

    try {
      await _db.collection(_collection).doc(listing.id).update(listing.toFirestore());
    } catch (e) {
      debugPrint('[ListingService] updateListing online failed, queueing offline: $e');
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeUpdate,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'listing': _serializeListingForQueue(listing, sellerId: listing.sellerId),
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<bool> deleteListing(Listing listing) async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeDelete,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'imageURLs': listing.imageURLs,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    }

    try {
      await _deleteListingOnline(listing.id, listing.imageURLs);
      return false;
    } catch (e) {
      debugPrint('[ListingService] deleteListing online failed, queueing offline: $e');
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeDelete,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'imageURLs': listing.imageURLs,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    }
  }

  Future<void> _deleteListingOnline(String listingId, List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
    }
    await _db.collection(_collection).doc(listingId).delete();
  }

  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      debugPrint('Connectivity check result: $result');
      return _hasConnectivity(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return true;
    }
  }

  static bool _hasConnectivity(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((e) => e != ConnectivityResult.none);
    }
    return true;
  }

  Future<void> _syncPendingOperations() async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      if (!await _isOnline()) return;

      final queue = await _loadQueue();
      if (queue.isEmpty) return;

      final idMap = <String, String>{};
      final remaining = <Map<String, dynamic>>[];

      for (final op in queue) {
        final type = op['type']?.toString() ?? '';
        final originalListingId = op['listingId']?.toString() ?? '';
        final resolvedListingId = idMap[originalListingId] ?? originalListingId;

        try {
          if (type == _typeCreate) {
            final createdId = await _applyCreateOperation(op);
            if (createdId != null && originalListingId != createdId) {
              idMap[originalListingId] = createdId;
            }
            continue;
          }

          if (type == _typeUpdate) {
            await _applyUpdateOperation(op, listingIdOverride: resolvedListingId);
            continue;
          }

          if (type == _typeDelete) {
            await _applyDeleteOperation(op, listingIdOverride: resolvedListingId);
            continue;
          }

          remaining.add(op);
        } catch (e) {
          debugPrint('[ListingService] sync op failed ($type): $e');
          remaining.add(op);
        }
      }

      await _saveQueue(remaining);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<String?> _applyCreateOperation(Map<String, dynamic> op) async {
    final listingRaw = op['listing'];
    if (listingRaw is! Map) return null;

    final listingMap = Map<String, dynamic>.from(listingRaw);
    final sellerId = op['sellerId']?.toString() ?? listingMap['sellerId']?.toString() ?? '';
    final shouldGeneratePendingTags = op['pendingTags'] == true;

    final imagePaths = (op['imagePaths'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final existingRemoteListingId = op['remoteListingId']?.toString() ?? '';
    final remoteListingId = existingRemoteListingId.isNotEmpty
        ? existingRemoteListingId
        : _db.collection(_collection).doc().id;

    if (existingRemoteListingId.isEmpty) {
      final imageUrls = <String>[];
      for (int i = 0; i < imagePaths.length && i < 5; i++) {
        final path = imagePaths[i];
        if (path.trim().isEmpty) continue;
        final url = await _uploadImage(XFile(path), remoteListingId, i);
        imageUrls.add(url);
      }

      final firestoreData = _queuedListingToFirestoreData(listingMap)
        ..addAll({
          'sellerId': sellerId,
          'createdAt': FieldValue.serverTimestamp(),
          'imageURLs': imageUrls,
          'imagePath': imageUrls.isNotEmpty ? imageUrls[0] : '',
          'tagsPending': shouldGeneratePendingTags,
        });

      await _db.collection(_collection).doc(remoteListingId).set(firestoreData);
      op['remoteListingId'] = remoteListingId;
    }

    if (shouldGeneratePendingTags) {
      await _generateAndUpdateTags(
        listingId: remoteListingId,
        imagePaths: imagePaths,
      );
    }

    return remoteListingId;
  }

  Future<void> _applyUpdateOperation(
    Map<String, dynamic> op, {
    required String listingIdOverride,
  }) async {
    if (listingIdOverride.trim().isEmpty || listingIdOverride.startsWith('local_')) {
      throw StateError('Update is waiting for local create sync.');
    }

    final listingRaw = op['listing'];
    if (listingRaw is! Map) return;

    final firestoreData = _queuedListingToFirestoreData(Map<String, dynamic>.from(listingRaw));
    await _db.collection(_collection).doc(listingIdOverride).update(firestoreData);
  }

  Future<void> _applyDeleteOperation(
    Map<String, dynamic> op, {
    required String listingIdOverride,
  }) async {
    if (listingIdOverride.trim().isEmpty) return;

    final imageUrls = (op['imageURLs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    if (listingIdOverride.startsWith('local_')) {
      throw StateError('Delete is waiting for local create sync.');
    }

    await _deleteListingOnline(listingIdOverride, imageUrls);
  }

  Future<void> _generateAndUpdateTags({
    required String listingId,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) return;

    final pathsToAnalyze = imagePaths
        .where((path) => path.trim().isNotEmpty)
        .take(_maxAiTagImages)
        .toList(growable: false);
    if (pathsToAnalyze.isEmpty) return;

    try {
      final tagMapTasks = pathsToAnalyze
          .map(
            (path) => _imageAnalysisService
                .analyzeImage(XFile(path))
                .then((analysis) => analysis.toListingTagsMap())
                .catchError((error, _) {
                  debugPrint(
                    '[ListingService] AI tag generation failed for image "$path": $error',
                  );
                  return <String, List<String>>{};
                }),
          )
          .toList(growable: false);

      final rawTagMaps = await Future.wait(tagMapTasks);
      final serializableTagMaps = rawTagMaps
          .map(
            (tagMap) => tagMap.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          )
          .toList(growable: false);

      // Merge and dedupe tags off the UI/main isolate to avoid jank.
      final generatedTags = await compute(
        _mergeAndFlattenTagMapsIsolate,
        serializableTagMaps,
      );

      if (generatedTags.isEmpty) return;

      await _db.collection(_collection).doc(listingId).update({
        'tags': generatedTags,
        'tagsPending': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ListingService] pending AI tag generation failed for $listingId: $e');
      rethrow;
    }
  }

  Future<void> _enqueueOperation(Map<String, dynamic> operation) async {
    final queue = await _loadQueue();
    final type = operation['type']?.toString() ?? '';
    final listingId = operation['listingId']?.toString() ?? '';

    if (type == _typeCreate) {
      queue.removeWhere(
        (op) =>
            (op['type']?.toString() == _typeCreate || op['type']?.toString() == _typeUpdate) &&
            op['listingId']?.toString() == listingId,
      );
      queue.add(operation);
      await _saveQueue(queue);
      return;
    }

    if (type == _typeUpdate) {
      final createIndex = queue.indexWhere(
        (op) => op['type']?.toString() == _typeCreate && op['listingId']?.toString() == listingId,
      );

      if (createIndex >= 0) {
        final existingCreate = queue[createIndex];
        existingCreate['listing'] = operation['listing'];
        queue[createIndex] = existingCreate;
      } else {
        queue.removeWhere(
          (op) => op['type']?.toString() == _typeUpdate && op['listingId']?.toString() == listingId,
        );
        queue.add(operation);
      }

      await _saveQueue(queue);
      return;
    }

    if (type == _typeDelete) {
      final hasLocalCreate = queue.any(
        (op) => op['type']?.toString() == _typeCreate && op['listingId']?.toString() == listingId,
      );

      if (hasLocalCreate) {
        queue.removeWhere(
          (op) =>
              (op['type']?.toString() == _typeCreate || op['type']?.toString() == _typeUpdate) &&
              op['listingId']?.toString() == listingId,
        );
      } else {
        queue.removeWhere(
          (op) =>
              (op['type']?.toString() == _typeUpdate || op['type']?.toString() == _typeDelete) &&
              op['listingId']?.toString() == listingId,
        );
        queue.add(operation);
      }

      await _saveQueue(queue);
      return;
    }

    queue.add(operation);
    await _saveQueue(queue);
  }

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingOpsStorageKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOpsStorageKey, jsonEncode(queue));
  }

  Map<String, dynamic> _serializeListingForQueue(
    Listing listing, {
    required String sellerId,
  }) {
    final map = Map<String, dynamic>.from(listing.toFirestore());
    map['sellerId'] = sellerId;
    map['createdAt'] = listing.createdAt?.toIso8601String();
    map['soldAt'] = listing.soldAt?.toIso8601String();
    return map;
  }

  Map<String, dynamic> _queuedListingToFirestoreData(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

    final createdAtRaw = map['createdAt'];
    if (createdAtRaw is String && createdAtRaw.trim().isNotEmpty) {
      map['createdAt'] = DateTime.tryParse(createdAtRaw);
    }

    final soldAtRaw = map['soldAt'];
    if (soldAtRaw is String && soldAtRaw.trim().isNotEmpty) {
      map['soldAt'] = DateTime.tryParse(soldAtRaw);
    }

    return map;
  }

  Listing _cloneListingWith(
    Listing listing, {
    required String id,
    required String sellerId,
    required DateTime createdAt,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId,
      title: listing.title,
      price: listing.price,
      conditionTag: listing.conditionTag,
      description: listing.description,
      sellerName: listing.sellerName,
      exchangeType: listing.exchangeType,
      tags: listing.tags,
      rating: listing.rating,
      imageName: listing.imageName,
      createdAt: createdAt,
      soldAt: listing.soldAt,
      imagePath: listing.imagePath,
      imageURLs: listing.imageURLs,
      size: listing.size,
      status: listing.status,
      saved: listing.saved,
    );
  }

  String _operationId() => 'op_${DateTime.now().microsecondsSinceEpoch}';

  String _localListingId() => 'local_${DateTime.now().microsecondsSinceEpoch}';

  String _normalizeExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.jpg')) return 'jpg';
    if (lower.endsWith('.jpeg')) return 'jpg';
    return 'jpg';
  }

  String _buildUniqueFileName(int index, String ext) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return 'image_${index}_$stamp.$ext';
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  User? get user => FirebaseAuth.instance.currentUser;

  List<String> _mergeAndFlattenTagMapsIsolate(List<Map<String, List<String>>> tagMaps) {
    final output = <String>[];

    for (final tagMap in tagMaps) {
      for (final key in const ['category', 'color', 'style', 'pattern']) {
        output.addAll(tagMap[key] ?? const []);
      }
    }

    final deduped = <String>[];
    for (final tag in output) {
      final value = tag.trim();
      if (value.isEmpty) continue;
      if (!deduped.contains(value)) {
        deduped.add(value);
      }
    }

    return deduped;
  }
}
