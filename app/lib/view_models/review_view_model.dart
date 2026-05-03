import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/pending_review_storage.dart';

class ReviewViewModel extends ChangeNotifier {
  final PendingReviewStorage _storage = PendingReviewStorage();
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;
  String? _error;
  String? get error => _error;

  Future<void> submitReview({
    required String productId,
    required String comment,
    required int rating,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _error = 'User not logged in';
        _isSubmitting = false;
        notifyListeners();
        return;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _storage.addPendingReview(
        productId: productId,
        userId: userId,
        comment: comment,
        rating: rating,
        timestamp: timestamp,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isSubmitting = false;
    notifyListeners();
  }
}
