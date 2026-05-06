import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/seller_performance_period.dart';

/// Firestore access for seller-performance feedback.
///
/// This service answers the Type 2 business question by counting how many
/// listings a seller has successfully sold within a selected time window.
class SellerPerformanceService {
  SellerPerformanceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final String _collection = 'meetup_transactions';

  Future<int> countSoldListingsForSeller({
    required String sellerId,
    required SellerPerformancePeriod period,
  }) {
    final window = period.window;
    return countSoldListingsInWindow(
      sellerId: sellerId,
      start: window.start,
      end: window.end,
    );
  }

  Stream<int> watchSoldListingsForSeller({
    required String sellerId,
    required SellerPerformancePeriod period,
  }) {
    final window = period.window;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    final verified = user != null && user.emailVerified && email.endsWith('@uniandes.edu.co');
    if (!verified) {
      debugPrint('[SellerPerformanceService] watchSoldListingsForSeller: user not verified - returning zero stream');
      return Stream.value(0);
    }

    return _db
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final status = (data['status'] as String?)?.toLowerCase() ?? '';
            if (status != 'confirmed') return false;

            final buyerId = (data['buyerId'] as String?) ?? '';
            if (buyerId == sellerId) return false;

            final confirmedAtValue = data['confirmedAt'];
            final confirmedAt =
                confirmedAtValue is Timestamp ? confirmedAtValue.toDate() : null;
            if (confirmedAt == null) return false;

            return !confirmedAt.isBefore(window.start) && confirmedAt.isBefore(window.end);
          }).length;
        }).handleError((e, st) {
          debugPrint('[SellerPerformanceService] Firestore snapshot error: $e');
        });
  }

  Future<int> countSoldListingsInWindow({
    required String sellerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final query = _db
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
      .where('status', isEqualTo: 'confirmed')
      .where('confirmedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('confirmedAt', isLessThan: Timestamp.fromDate(end))
      .orderBy('confirmedAt', descending: true);

    try {
      final aggregateSnapshot = await query.count().get();
      return aggregateSnapshot.count ?? 0;
    } catch (aggregateError) {
      debugPrint(
        '[SellerPerformanceService] count aggregation failed, falling back to snapshot count: $aggregateError',
      );
      return _countWithSimpleFallback(
        sellerId: sellerId,
        start: start,
        end: end,
      );
    }
  }

  Stream<int> watchPublishedListingsForSeller({
    required String sellerId,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    final verified = user != null && user.emailVerified && email.endsWith('@uniandes.edu.co');
    if (!verified) {
      debugPrint('[SellerPerformanceService] watchPublishedListingsForSeller: user not verified - returning zero stream');
      return Stream.value(0);
    }

    return _db
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((e, st) {
          debugPrint('[SellerPerformanceService] Firestore snapshot error: $e');
        });
  }

  Future<int> _countWithSimpleFallback({
    required String sellerId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _db
        .collection(_collection)
        .where('sellerId', isEqualTo: sellerId)
        .get();

    return snapshot.docs.where((doc) {
      final data = doc.data();
      final status = (data['status'] as String?)?.toLowerCase() ?? '';
      if (status != 'confirmed') return false;

      final buyerId = (data['buyerId'] as String?) ?? '';
      if (buyerId == sellerId) return false;

      final confirmedAtValue = data['confirmedAt'];
      final confirmedAt = confirmedAtValue is Timestamp ? confirmedAtValue.toDate() : null;
      if (confirmedAt == null) return false;

      final isInWindow = !confirmedAt.isBefore(start) && confirmedAt.isBefore(end);
      return isInWindow;
    }).length;
  }
}
