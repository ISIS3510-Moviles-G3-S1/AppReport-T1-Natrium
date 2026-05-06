import 'dart:async';
import 'dart:convert';
import 'dart:collection';

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
  static const String _cachedListingsKey = 'cached_listings';
  static const int _maxCachedListings = 10;
  static const String _listedCacheBoxName = 'listings_cache';
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

  // Stores listings in Hive using a LinkedHashMap so access order is preserved.
  Future<void> _cacheListings(List<Listing> listings) async {
    final box = await Hive.openBox(_listedCacheBoxName);
    final cache = _readLinkedListingCache(box.get(_cachedListingsKey));

    for (final listing in listings) {
      _touchListingCache(cache, listing.id, listing.toJson());
    }

    final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);
    await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));
    debugPrint('Cached ${trimmed.length} listings in Hive (LinkedHashMap LRU, limit=$_maxCachedListings).');
  }

  static LinkedHashMap<String, Map<String, dynamic>> _readLinkedListingCache(dynamic raw) {
    final cache = LinkedHashMap<String, Map<String, dynamic>>();

    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          cache[key] = map.containsKey('listing') && map['listing'] is Map
              ? Map<String, dynamic>.from(map['listing'] as Map)
              : map;
        }
      }
      return cache;
    }

    if (raw is List) {
      for (final value in raw) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final listing = map.containsKey('listing') && map['listing'] is Map
              ? Map<String, dynamic>.from(map['listing'] as Map)
              : map;
          final id = listing['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            cache[id] = listing;
          }
        }
      }
    }

    return cache;
  }

  static Map<String, Map<String, dynamic>> _serializeLinkedListingCache(
    LinkedHashMap<String, Map<String, dynamic>> cache,
  ) {
    return LinkedHashMap<String, Map<String, dynamic>>.from(cache);
  }

  static void _touchListingCache(
    LinkedHashMap<String, Map<String, dynamic>> cache,
    String listingId,
    Map<String, dynamic> listingJson,
  ) {
    if (listingId.trim().isEmpty) return;
    cache.remove(listingId);
    cache[listingId] = Map<String, dynamic>.from(listingJson);
  }

  static LinkedHashMap<String, Map<String, dynamic>> _trimLinkedListingCache(
    LinkedHashMap<String, Map<String, dynamic>> cache,
    int max,
  ) {
    if (max <= 0) return LinkedHashMap<String, Map<String, dynamic>>();

    final trimmed = LinkedHashMap<String, Map<String, dynamic>>.from(cache);
    while (trimmed.length > max) {
      trimmed.remove(trimmed.keys.first);
    }
    return trimmed;
  }

  // Restores cached listings from Hive and updates access order (LRU)
  Future<List<Listing>> _getCachedListings() async {
    final box = await Hive.openBox(_listedCacheBoxName);
    final cache = _readLinkedListingCache(box.get(_cachedListingsKey));
    final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);

    if (trimmed.length != cache.length) {
      await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));
    }

    return trimmed.values.map(Listing.fromJson).toList();
  }

  /// Helper for tests: trim a LinkedHashMap in LRU order and return kept keys.
  static List<String> trimLinkedListingCacheKeys(
    LinkedHashMap<String, Map<String, dynamic>> cache,
    int max,
  ) {
    return _trimLinkedListingCache(cache, max).keys.toList(growable: false);
  }

  Stream<List<Listing>> getListings() async* {
    final isOnline = await _isOnline();
    final currentUser = FirebaseAuth.instance.currentUser;
    final canReadRemote = isOnline && _canUseFirestore(currentUser);
    debugPrint('Checking online status: $isOnline');

    if (canReadRemote) {
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

            await _cacheListings(listings); // Store in Hive
            debugPrint('Listings cached in Hive.');
            return listings;
          });
    } else {
      debugPrint('Using cached listings from Hive (offline or no Firestore access)...');
      final cachedListings = await _getCachedListings();
      debugPrint('Cached listings retrieved: ${cachedListings.length} items.');
      yield cachedListings;
    }
  }

  Stream<List<Listing>> getListingsBySellerId(String sellerId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_canUseFirestore(currentUser)) {
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

    return Stream.fromFuture(_getCachedListings().then((cachedListings) {
      final listings = cachedListings.where((listing) => listing.sellerId == sellerId).toList();
      listings.sort((a, b) {
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
      });
      return listings;
    }));
  }

  Future<Listing?> getListingById(String id) async {
    final box = await Hive.openBox(_listedCacheBoxName);
    final cache = _readLinkedListingCache(box.get(_cachedListingsKey));

    final cachedListing = cache.remove(id);
    if (cachedListing != null) {
      cache[id] = cachedListing;
      final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);
      await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));
      return Listing.fromJson(cachedListing);
    }

    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    final listing = Listing.fromFirestore(doc);
    _touchListingCache(cache, listing.id, listing.toJson());
    final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);
    await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));

    return listing;
  }

  static bool _isVerifiedStudentUser(User? user) {
    final email = user?.email?.trim().toLowerCase() ?? '';
    return user != null && user.emailVerified && email.endsWith('@uniandes.edu.co');
  }

  static bool _canUseFirestore(User? user) => _isVerifiedStudentUser(user);

  Future<void> _upsertCachedListing(Listing listing) async {
    final box = await Hive.openBox(_listedCacheBoxName);
    final cache = _readLinkedListingCache(box.get(_cachedListingsKey));
    _touchListingCache(cache, listing.id, listing.toJson());
    final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);
    await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));
  }

  Future<void> _removeCachedListing(String listingId) async {
    final box = await Hive.openBox(_listedCacheBoxName);
    final cache = _readLinkedListingCache(box.get(_cachedListingsKey));
    cache.remove(listingId);
    final trimmed = _trimLinkedListingCache(cache, _maxCachedListings);
    await box.put(_cachedListingsKey, _serializeLinkedListingCache(trimmed));
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
    final shouldQueuePendingTags = listing.tags.isEmpty && images.isNotEmpty;
    final isOnline = await _isOnline();

    final user = FirebaseAuth.instance.currentUser;
    final canCreateRemote = isOnline && _canUseFirestore(user);
    final userId = user?.uid ?? 'unknown_user';

    if (!canCreateRemote) {
      final localId = _localListingId();
      final queuedListing = _cloneListingWith(
        listing,
        id: localId,
        sellerId: userId,
        createdAt: DateTime.now(),
      );
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeCreate,
        'listingId': localId,
        'sellerId': userId,
        'listing': _serializeListingForQueue(listing, sellerId: userId),
        'imagePaths': images.map((e) => e.path).where((e) => e.trim().isNotEmpty).toList(),
        'pendingTags': shouldQueuePendingTags,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });

      await _upsertCachedListing(queuedListing);

      return queuedListing;
    }

    if (user == null) throw Exception('User not authenticated');

    try {
      final created = await _createListingOnline(
        listing: listing,
        images: images,
        sellerId: user.uid,
      );
      await _upsertCachedListing(created);
      return created;
    } catch (e) {
      debugPrint('[ListingService] createListing online failed, queueing offline: $e');
      final localId = _localListingId();
      final queuedListing = _cloneListingWith(
        listing,
        id: localId,
        sellerId: user.uid,
        createdAt: DateTime.now(),
      );
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeCreate,
        'listingId': localId,
        'sellerId': user.uid,
        'listing': _serializeListingForQueue(listing, sellerId: user.uid),
        'imagePaths': images.map((e) => e.path).where((e) => e.trim().isNotEmpty).toList(),
        'pendingTags': shouldQueuePendingTags,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });

      await _upsertCachedListing(queuedListing);
      return queuedListing;
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

  Future<bool> updateListing(Listing listing) async {
    final isOnline = await _isOnline();
    final currentUser = FirebaseAuth.instance.currentUser;
    final canWriteRemote = isOnline && _canUseFirestore(currentUser);

    if (!canWriteRemote) {
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeUpdate,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'listing': _serializeListingForQueue(listing, sellerId: listing.sellerId),
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _upsertCachedListing(listing);
      return true; // queued offline
    }

    try {
      await _db.collection(_collection).doc(listing.id).update(listing.toFirestore());
      await _upsertCachedListing(listing);
      return false; // updated online
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
      await _upsertCachedListing(listing);
      return true; // queued after online failure
    }
  }

  Future<bool> deleteListing(Listing listing) async {
    final isOnline = await _isOnline();
    final currentUser = FirebaseAuth.instance.currentUser;
    final canWriteRemote = isOnline && _canUseFirestore(currentUser);

    if (!canWriteRemote) {
      await _enqueueOperation({
        'opId': _operationId(),
        'type': _typeDelete,
        'listingId': listing.id,
        'sellerId': listing.sellerId,
        'imageURLs': listing.imageURLs,
        'queuedAt': DateTime.now().toUtc().toIso8601String(),
      });
      await _removeCachedListing(listing.id);
      return true;
    }

    try {
      await _deleteListingOnline(listing.id, listing.imageURLs);
      await _removeCachedListing(listing.id);
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
      await _removeCachedListing(listing.id);
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

      final currentUser = FirebaseAuth.instance.currentUser;
      if (!_canUseFirestore(currentUser)) {
        debugPrint('[ListingService] Sync skipped: no verified Firestore user available.');
        return;
      }

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
    final queuedSellerId = op['sellerId']?.toString() ?? listingMap['sellerId']?.toString() ?? '';
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Security: validate seller ownership during sync
    // - If queued with specific UID and current user mismatches: reject (prevent impersonation)
    // - Otherwise: allow sync (offline users need flexibility, and matched users can always sync)
    if (queuedSellerId != 'unknown_user' && 
        currentUser != null && 
        queuedSellerId != currentUser.uid) {
      throw StateError(
        'Cannot sync this listing: it was created by a different user. '
        'Log in as the original user to sync this listing.',
      );
    }

    // Use current authenticated user if available, otherwise use queued sellerId
    final sellerId = currentUser?.uid ?? queuedSellerId;
    if (sellerId.isEmpty || sellerId == 'unknown_user') {
      throw StateError(
        'Cannot sync listing: no user context available. '
        'Log in to sync this listing.',
      );
    }

    debugPrint('[ListingService] Syncing listing with seller=$sellerId');
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

      await _upsertCachedListing(
        Listing.fromJson({
          ...listingMap,
          'id': remoteListingId,
          'sellerId': sellerId,
          'imageURLs': imageUrls,
          'imagePath': imageUrls.isNotEmpty ? imageUrls[0] : '',
          'tagsPending': shouldGeneratePendingTags,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
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
    await _upsertCachedListing(Listing.fromJson({
      ...firestoreData,
      'id': listingIdOverride,
    }));
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
    await _removeCachedListing(listingIdOverride);
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
