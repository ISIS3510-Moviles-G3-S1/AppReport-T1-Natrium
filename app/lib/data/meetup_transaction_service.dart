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
      transaction.update(listingRef, {
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });

      return meetupTx.copyWith(
        status: MeetupTransactionStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
    });
  }

  Stream<Set<String>> watchConfirmedListingIds() {
    return _db
        .collection(_collection)
        .where('status', isEqualTo: meetupStatusToString(MeetupTransactionStatus.confirmed))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => (doc.data()['listingId'] as String?) ?? '')
              .where((id) => id.trim().isNotEmpty)
              .toSet();
        });
  }
}