import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/meetup_qr_payload.dart';
import '../data/meetup_transaction_service.dart';
import '../models/meetup_transaction.dart';

class GenerateQrViewModel extends ChangeNotifier {
  GenerateQrViewModel({MeetupTransactionService? service})
    : _service = service ?? MeetupTransactionService();

  final MeetupTransactionService _service;

  bool _isLoading = false;
  String? _errorMessage;
  MeetupTransaction? _transaction;
  String? _qrPayload;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MeetupTransaction? get transaction => _transaction;
  String? get qrPayload => _qrPayload;
  bool get hasQrPayload => _qrPayload != null && _qrPayload!.isNotEmpty;

  Future<void> generateQrForListing({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required String currentUserId,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    _transaction = null;
    _qrPayload = null;
    notifyListeners();

    try {
      if (currentUserId != sellerId) {
        throw const MeetupTransactionException(
          code: 'permission-denied',
          message: 'Only the seller can generate a meetup QR code.',
        );
      }

      final tx = await _service.createPendingTransaction(
        listingId: listingId,
        sellerId: sellerId,
        buyerId: buyerId,
      );

      _transaction = tx;
      _qrPayload =
          MeetupQrPayload(
            transactionId: tx.transactionId,
            listingId: tx.listingId,
            sellerId: tx.sellerId,
            buyerId: tx.buyerId,
          ).encode();
    } on MeetupTransactionException catch (e) {
      _errorMessage = e.message;
    } on FirebaseException catch (e) {
      _errorMessage =
          e.code == 'permission-denied'
              ? 'Firestore permission denied. Update/deploy firestore.rules first.'
              : 'Firestore error: ${e.message ?? e.code}';
    } catch (_) {
      _errorMessage = 'Could not generate QR. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
