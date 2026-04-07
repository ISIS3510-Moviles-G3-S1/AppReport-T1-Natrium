import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';

class ListingService {
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
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _collection = 'listings';

  Stream<List<Listing>> getListings() {
    return _db
        .collection(_collection)
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
    final docRef = _db.collection(_collection).doc();
    final listingId = docRef.id;
    List<String> imageUrls = [];
    for (int i = 0; i < images.length && i < 5; i++) {
      final url = await _uploadImage(images[i], listingId, i);
      imageUrls.add(url);
    }
    final data = listing.toFirestore()
      ..addAll({
        'sellerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'imageURLs': imageUrls,
        'imagePath': imageUrls.isNotEmpty ? imageUrls[0] : '',
      });
    await docRef.set(data);

    // Analytics: track new item uploaded
    final category = (listing.tags.isNotEmpty ? listing.tags[0] : 'Other');
    AnalyticsService.instance.track(
      AnalyticsEvent.newItemUploaded(
        userId: user.uid,
        category: category,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    final doc = await docRef.get();
    return Listing.fromFirestore(doc);
  }

  Future<void> updateListing(Listing listing) async {
    await _db.collection(_collection).doc(listing.id).update(listing.toFirestore());
  }

  Future<void> deleteListing(Listing listing) async {
    for (final url in listing.imageURLs) {
      if (url.isNotEmpty) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (_) {}
      }
    }
    await _db.collection(_collection).doc(listing.id).delete();
  }

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
}
