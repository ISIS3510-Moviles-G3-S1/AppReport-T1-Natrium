import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/pending_review_storage.dart';

class ReviewSyncService {
  final PendingReviewStorage _storage = PendingReviewStorage();
  final Future<void> Function(Map<String, dynamic> review) sendReviewToBackend;
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;

  ReviewSyncService({required this.sendReviewToBackend}) {
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingReviews();
      }
    });
  }

  Future<void> syncPendingReviews() async {
    final pending = await _storage.getPendingReviews();
    for (final review in pending) {
      try {
        await sendReviewToBackend(review);
        await _storage.markReviewAsSynced(review['id'] as int);
      } catch (e) {
        debugPrint('Failed to sync review: $e');
      }
    }
  }
}
