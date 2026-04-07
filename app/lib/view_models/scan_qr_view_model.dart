import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/meetup_qr_payload.dart';
import '../data/meetup_transaction_service.dart';
import '../models/meetup_transaction.dart';

class ScanQrViewModel extends ChangeNotifier {
  ScanQrViewModel({MeetupTransactionService? service})
    : _service = service ?? MeetupTransactionService();

  final MeetupTransactionService _service;

  bool _isProcessing = false;
  bool _hasHandledScan = false;
  String? _errorMessage;
  String? _successMessage;
  String? _lastExpectedBuyerId;
  String? _lastScannerUserId;
  MeetupTransaction? _confirmedTransaction;

  bool get isProcessing => _isProcessing;
  bool get hasHandledScan => _hasHandledScan;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get lastExpectedBuyerId => _lastExpectedBuyerId;
  String? get lastScannerUserId => _lastScannerUserId;
  MeetupTransaction? get confirmedTransaction => _confirmedTransaction;
  bool get isConfirmed => _confirmedTransaction != null;

  Future<void> processScannedCode({
    required String? rawValue,
    required String currentUserId,
  }) async {
    if (_isProcessing || _hasHandledScan) return;

    _setProcessing(true);
    _errorMessage = null;
    _successMessage = null;
    _lastExpectedBuyerId = null;
    _lastScannerUserId = currentUserId;
    notifyListeners();

    try {
      if (rawValue == null || rawValue.trim().isEmpty) {
        throw const FormatException('Empty QR data');
      }

      final payload = MeetupQrPayload.decode(rawValue);
      _lastExpectedBuyerId = payload.buyerId;
      _lastScannerUserId = currentUserId;

      if (currentUserId != payload.buyerId) {
        _errorMessage =
            'Wrong account. Scanner UID: $currentUserId. QR expects buyer UID: ${payload.buyerId}.';
        return;
      }

      final transaction = await _service.confirmFromQrPayload(
        payload: payload,
        confirmerUserId: currentUserId,
      );

      _confirmedTransaction = transaction;
      _successMessage = 'Pickup confirmed successfully. Transaction updated.';
      _hasHandledScan = true;
    } on FormatException {
      _errorMessage = 'Invalid QR format. Please scan a valid meetup QR.';
    } on MeetupTransactionException catch (e) {
      _errorMessage = e.message;
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          _errorMessage =
              'Firestore permission denied while confirming. Check deployed rules.';
          break;
        case 'unavailable':
          _errorMessage =
              'Firestore temporarily unavailable. Check network and try again.';
          break;
        case 'failed-precondition':
          _errorMessage =
              'Firestore failed precondition: ${e.message ?? e.code}';
          break;
        default:
          _errorMessage = 'Firestore error (${e.code}): ${e.message ?? ''}'.trim();
      }
      debugPrint('[ScanQr] FirebaseException code=${e.code} message=${e.message}');
    } catch (e, st) {
      debugPrint('[ScanQr] Unexpected error: $e');
      debugPrint(st.toString());
      _errorMessage = 'Could not confirm transaction. Try again.';
    } finally {
      _setProcessing(false);
    }
  }

  void resetForRescan() {
    _isProcessing = false;
    _hasHandledScan = false;
    _errorMessage = null;
    _successMessage = null;
    _lastExpectedBuyerId = null;
    _lastScannerUserId = null;
    _confirmedTransaction = null;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}
