import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/seller_performance_period.dart';
import '../data/seller_performance_service.dart';
import 'session_view_model.dart';

enum SellerPerformanceStatus { initial, loading, success, error }

class SellerPerformanceViewModel extends ChangeNotifier {
  SellerPerformanceViewModel(
    SessionViewModel session, {
    SellerPerformanceService? service,
  })  : _session = session,
        _service = service ?? SellerPerformanceService() {
    _session.addListener(_handleSessionChanged);
    Future.microtask(loadPerformance);
  }

  final SellerPerformanceService _service;
  SessionViewModel _session;

  SellerPerformancePeriod _selectedPeriod = SellerPerformancePeriod.currentMonth;
  SellerPerformanceStatus _status = SellerPerformanceStatus.initial;
  int _soldCount = 0;
  int _publishedCount = 0;
  String _feedbackMessage = '';
  String? _errorMessage;
  String? _loadedUserId;
  int _loadToken = 0;
  StreamSubscription<int>? _soldCountSubscription;
  StreamSubscription<int>? _publishedCountSubscription;

  SellerPerformancePeriod get selectedPeriod => _selectedPeriod;
  SellerPerformanceStatus get status => _status;
  int get soldCount => _soldCount;
  int get publishedCount => _publishedCount;
  String get soldCountDisplay => '$soldCount/$publishedCount';
  String get feedbackMessage => _feedbackMessage;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == SellerPerformanceStatus.loading;
  bool get hasError => _status == SellerPerformanceStatus.error;
  bool get hasData => _status == SellerPerformanceStatus.success;

  String get periodLabel => _selectedPeriod.label;

  void updateSession(SessionViewModel session) {
    if (identical(_session, session)) return;
    _session.removeListener(_handleSessionChanged);
    _session = session;
    _session.addListener(_handleSessionChanged);
    Future.microtask(loadPerformance);
  }

  Future<void> loadPerformance() async {
    final user = _session.currentUser;
    if (user == null) {
      await _soldCountSubscription?.cancel();
      _soldCountSubscription = null;
      _setError('Sign in to see your seller performance.');
      return;
    }

    final requestedUserId = user.uid;
    final requestedPeriod = _selectedPeriod;
    final requestToken = ++_loadToken;
    await _soldCountSubscription?.cancel();
    await _publishedCountSubscription?.cancel();
    _soldCountSubscription = null;
    _publishedCountSubscription = null;
    _status = SellerPerformanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Subscribe to published listings count
      _publishedCountSubscription = _service
          .watchPublishedListingsForSeller(sellerId: requestedUserId)
          .listen(
            (count) {
              if (_loadToken != requestToken || _session.currentUser?.uid != requestedUserId) {
                return;
              }
              _publishedCount = count;
              notifyListeners();
            },
          );

      // Subscribe to sold listings count
      _soldCountSubscription = _service
          .watchSoldListingsForSeller(
            sellerId: requestedUserId,
            period: requestedPeriod,
          )
          .listen(
            (count) {
              if (_loadToken != requestToken || _session.currentUser?.uid != requestedUserId) {
                return;
              }

              _loadedUserId = requestedUserId;
              _soldCount = count;
              _feedbackMessage = _buildFeedbackMessage(count, _publishedCount, requestedPeriod);
              _status = SellerPerformanceStatus.success;
              _errorMessage = null;
              notifyListeners();
            },
            onError: (error) {
              if (_loadToken != requestToken || _session.currentUser?.uid != requestedUserId) {
                return;
              }
              _setError('Unable to load seller performance: $error');
            },
          );
    } on FirebaseException catch (e) {
      if (_loadToken != requestToken || _session.currentUser?.uid != requestedUserId) {
        return;
      }
      _setError(
        e.code == 'permission-denied'
            ? 'Firestore permission denied. Check your security rules.'
            : 'Firestore error: ${e.message ?? e.code}',
      );
    } catch (e) {
      if (_loadToken != requestToken || _session.currentUser?.uid != requestedUserId) {
        return;
      }
      _setError('Unable to load seller performance: $e');
    }
  }

  Future<void> refresh() => loadPerformance();

  void setSelectedPeriod(SellerPerformancePeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
    Future.microtask(loadPerformance);
  }

  String _buildFeedbackMessage(int count, int published, SellerPerformancePeriod period) {
    final periodText = period.shortPhrase;
    if (count <= 0) {
      return 'No items sold $periodText yet. Try improving your photos or adjusting your price.';
    }

    final itemWord = count == 1 ? 'item' : 'items';
    final ratio = '$count/$published';
    return 'Great job! You sold $ratio $itemWord $periodText.';
  }

  void _handleSessionChanged() {
    final userId = _session.currentUser?.uid;
    if (userId != _loadedUserId) {
      Future.microtask(loadPerformance);
    }
  }

  void _setError(String message) {
    _status = SellerPerformanceStatus.error;
    _soldCount = 0;
    _feedbackMessage = '';
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _soldCountSubscription?.cancel();
    _publishedCountSubscription?.cancel();
    _session.removeListener(_handleSessionChanged);
    super.dispose();
  }
}
