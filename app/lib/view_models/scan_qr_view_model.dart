import 'package:flutter/foundation.dart';

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
  MeetupTransaction? _confirmedTransaction;

  bool get isProcessing => _isProcessing;
  bool get hasHandledScan => _hasHandledScan;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
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
    notifyListeners();

    try {
      if (rawValue == null || rawValue.trim().isEmpty) {
        throw const FormatException('Empty QR data');
      }

      final payload = MeetupQrPayload.decode(rawValue);
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
    } catch (_) {
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
    _confirmedTransaction = null;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}
