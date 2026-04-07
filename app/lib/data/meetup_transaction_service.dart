import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/meetup_qr_payload.dart';
import '../models/meetup_transaction.dart';

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
    required String buyerId,
  }) async {
    if (listingId.trim().isEmpty ||
        sellerId.trim().isEmpty ||
        buyerId.trim().isEmpty) {
      throw const MeetupTransactionException(
        code: 'invalid-input',
        message: 'Listing ID, seller ID, and buyer ID are required.',
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

    final docRef = _db.collection(_collection).doc();
    await docRef.set({
      'transactionId': docRef.id,
      'listingId': listingId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'status': meetupStatusToString(MeetupTransactionStatus.pending),
      'createdAt': FieldValue.serverTimestamp(),
      'confirmedAt': null,
    });

    final created = await docRef.get();
    return MeetupTransaction.fromFirestore(created);
  }

  Future<MeetupTransaction> confirmFromQrPayload({
    required MeetupQrPayload payload,
    required String confirmerUserId,
  }) async {
    if (confirmerUserId != payload.buyerId) {
      throw const MeetupTransactionException(
        code: 'wrong-buyer',
        message: 'This QR can only be confirmed by the assigned buyer.',
      );
    }

    final txRef = _db.collection(_collection).doc(payload.transactionId);
    final listingRef = _db.collection('listings').doc(payload.listingId);

    return _db.runTransaction((transaction) async {
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
          meetupTx.sellerId == payload.sellerId &&
          meetupTx.buyerId == payload.buyerId;

      if (!payloadMatchesTransaction) {
        throw const MeetupTransactionException(
          code: 'invalid-qr-data',
          message: 'QR data does not match the transaction in Firestore.',
        );
      }

      final listingSnap = await transaction.get(listingRef);
      if (!listingSnap.exists) {
        throw const MeetupTransactionException(
          code: 'missing-listing',
          message: 'Listing not found for this transaction.',
        );
      }

      final listingData = listingSnap.data() ?? <String, dynamic>{};
      final listingSellerId = (listingData['sellerId'] as String?) ?? '';
      if (listingSellerId != payload.sellerId) {
        throw const MeetupTransactionException(
          code: 'wrong-seller',
          message: 'Listing owner does not match seller in QR.',
        );
      }

      transaction.update(txRef, {
        'status': meetupStatusToString(MeetupTransactionStatus.confirmed),
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      return meetupTx.copyWith(
        status: MeetupTransactionStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
    });
  }
}
