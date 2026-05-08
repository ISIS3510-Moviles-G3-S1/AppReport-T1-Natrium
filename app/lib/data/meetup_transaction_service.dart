import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../core/meetup_qr_payload.dart';
import '../models/meetup_transaction.dart';
import '../models/sustainability_impact.dart';

class MeetupTransactionException implements Exception {
  final String code;
  final String message;

  const MeetupTransactionException({required this.code, required this.message});

  @override
  String toString() => 'MeetupTransactionException($code): $message';
}

class MeetupTransactionService {
  MeetupTransactionService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final String _collection = 'meetup_transactions';

  Future<MeetupTransaction> createPendingTransaction({
    required String listingId,
    required String sellerId,
    required String sellerEmail,
    required String buyerEmail,
  }) async {
    if (listingId.trim().isEmpty ||
        sellerId.trim().isEmpty ||
        sellerEmail.trim().isEmpty ||
        buyerEmail.trim().isEmpty) {
      throw const MeetupTransactionException(
        code: 'invalid-input',
        message: 'Listing ID, seller ID, seller email, and buyer email are required.',
      );
    }

    final normalizedSellerEmail = sellerEmail.trim().toLowerCase();
    final normalizedBuyerEmail = buyerEmail.trim().toLowerCase();

    if (normalizedSellerEmail == normalizedBuyerEmail) {
      throw const MeetupTransactionException(
        code: 'invalid-buyer',
        message: 'Seller and buyer must use different email accounts.',
      );
    }

    final listingRef = _db.collection('listings').doc(listingId);
    final listingDoc = await listingRef.get();
    if (!listingDoc.exists) {
      throw const MeetupTransactionException(
        code: 'missing-listing',
        message: 'Listing does not exist.',
      );
    }

    final listingData = listingDoc.data() ?? <String, dynamic>{};
    final listingSellerId = (listingData['sellerId'] as String?) ?? '';
    if (listingSellerId != sellerId) {
      throw const MeetupTransactionException(
        code: 'wrong-seller',
        message: 'Only the listing seller can generate this meetup QR.',
      );
    }

    final listingStatus = (listingData['status'] as String?)?.toLowerCase() ?? '';
    if (listingStatus == 'sold') {
      throw const MeetupTransactionException(
        code: 'already-sold',
        message: 'This item is already sold. You cannot generate a new QR code.',
      );
    }

    final alreadyConfirmed = await _db
        .collection(_collection)
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: meetupStatusToString(MeetupTransactionStatus.confirmed))
        .limit(1)
        .get();
    if (alreadyConfirmed.docs.isNotEmpty) {
      throw const MeetupTransactionException(
        code: 'already-sold',
        message: 'This item is already sold. You cannot generate a new QR code.',
      );
    }

    final docRef = _db.collection(_collection).doc();
    await docRef.set({
      'transactionId': docRef.id,
      'listingId': listingId,
      'sellerId': sellerId,
      'sellerEmail': normalizedSellerEmail,
      'buyerEmail': normalizedBuyerEmail,
      'status': meetupStatusToString(MeetupTransactionStatus.pending),
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
    });

    final created = await docRef.get();
    return MeetupTransaction.fromFirestore(created);
  }

  Future<MeetupTransaction> confirmFromQrPayload({
    required MeetupQrPayload payload,
    required String confirmerUserEmail,
  }) async {
    if (confirmerUserEmail.trim().toLowerCase() != payload.buyerEmail) {
      throw const MeetupTransactionException(
        code: 'wrong-buyer',
        message: 'This QR can only be confirmed by the assigned buyer.',
      );
    }

    final txRef = _db.collection(_collection).doc(payload.transactionId);

    final outcome = await _db.runTransaction((transaction) async {
      final txSnap = await transaction.get(txRef);
      if (!txSnap.exists) {
        throw const MeetupTransactionException(
          code: 'missing-transaction',
          message: 'Transaction not found.',
        );
      }

      final meetupTx = MeetupTransaction.fromFirestore(txSnap);

      if (!meetupTx.isPending) {
        throw const MeetupTransactionException(
          code: 'already-confirmed',
          message: 'This transaction has already been confirmed.',
        );
      }

      final payloadMatchesTransaction =
          meetupTx.listingId == payload.listingId &&
          meetupTx.sellerEmail.trim().toLowerCase() == payload.sellerEmail &&
          meetupTx.buyerEmail.trim().toLowerCase() == payload.buyerEmail;

      if (!payloadMatchesTransaction) {
        throw const MeetupTransactionException(
          code: 'invalid-qr-data',
          message: 'QR data does not match the transaction in Firestore.',
        );
      }

      transaction.update(txRef, {
        'status': meetupStatusToString(MeetupTransactionStatus.confirmed),
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      final listingRef = _db.collection('listings').doc(meetupTx.listingId);
      final listingSnap = await transaction.get(listingRef);
      if (!listingSnap.exists) {
        throw const MeetupTransactionException(
          code: 'missing-listing',
          message: 'Listing not found while confirming transaction.',
        );
      }
      final listingData = listingSnap.data() ?? <String, dynamic>{};

      transaction.update(listingRef, {
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });

      final updatedTx = meetupTx.copyWith(
        status: MeetupTransactionStatus.confirmed,
        confirmedAt: DateTime.now(),
      );

      return <String, dynamic>{
        'transaction': updatedTx,
        'listingTitle': (listingData['title'] as String?) ?? '',
        'listingTags': List<String>.from(
          listingData['tags'] as List<dynamic>? ?? const <dynamic>[],
        ),
      };
    });

    final confirmedTx = outcome['transaction'] as MeetupTransaction;
    final listingTitle = (outcome['listingTitle'] as String?) ?? '';
    final listingTags = List<String>.from(
      outcome['listingTags'] as List<dynamic>? ?? const <dynamic>[],
    );

    final category = ImpactCategory.infer(tags: listingTags, title: listingTitle);
    final coeff = category.coefficients;

    AnalyticsService.instance.track(
      AnalyticsEvent.sustainabilityImpactPerTransaction(
        transactionId: confirmedTx.transactionId,
        listingId: confirmedTx.listingId,
        sellerId: confirmedTx.sellerId,
        category: category.name,
        waterSavedLiters: coeff.water,
        co2SavedKg: coeff.co2,
        wasteSavedKg: coeff.waste,
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ),
    );

    return confirmedTx;
  }

  Stream<Set<String>> watchConfirmedListingIds() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    final verified = user != null && user.emailVerified && email.endsWith('@uniandes.edu.co');
    if (!verified) {
      debugPrint('[MeetupTransactionService] watchConfirmedListingIds: user not verified - returning empty stream');
      return Stream.value(<String>{});
    }

    return _db
        .collection(_collection)
        .where('status', isEqualTo: meetupStatusToString(MeetupTransactionStatus.confirmed))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => (doc.data()['listingId'] as String?) ?? '')
              .where((id) => id.trim().isNotEmpty)
              .toSet();
        }).handleError((e, st) {
          debugPrint('[MeetupTransactionService] Firestore snapshot error: $e');
        });
  }
}