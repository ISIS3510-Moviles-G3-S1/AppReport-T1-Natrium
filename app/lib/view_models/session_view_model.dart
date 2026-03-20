import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_failure.dart';
import '../core/auth_service.dart';
import '../core/notification_service.dart';
import '../models/app_user.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel({
    required AuthService authService,
    NotificationService? notificationService,
  })  : _authService = authService,
        _notificationService = notificationService ?? NotificationService() {
    _authSubscription = _authService.authStateChanges.listen(
      (user) => _handleAuthState(user),
      onError: (_, __) {
        _setError('Session error. Please try again');
        _setLoading(false);
      },
    );
  }

  final AuthService _authService;
  final NotificationService _notificationService;
  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// =========================
  /// SIGN IN
  /// =========================
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      _setUser(user);

    } on AuthFailure catch (failure) {
      _setError(failure.message);
      rethrow;
    } catch (_) {
      const failure = AuthFailure('Unable to sign in. Please try again');
      _setError(failure.message);
      throw failure;
    } finally {
      _setLoading(false);
    }
  }

  /// =========================
  /// SIGN UP
  /// =========================
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      _setUser(user);

    } on AuthFailure catch (failure) {
      _setError(failure.message);
      rethrow;
    } catch (_) {
      const failure = AuthFailure('Unable to sign up. Please try again');
      _setError(failure.message);
      throw failure;
    } finally {
      _setLoading(false);
    }
  }

  /// =========================
  /// SIGN OUT
  /// =========================
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.signOut();
      _setUser(null);

    } on AuthFailure catch (failure) {
      _setError(failure.message);
      rethrow;
    } catch (_) {
      const failure = AuthFailure('Unable to sign out. Please try again');
      _setError(failure.message);
      throw failure;
    } finally {
      _setLoading(false);
    }
  }

  /// =========================
  /// AUTH STATE LISTENER
  /// =========================
  Future<void> _handleAuthState(User? firebaseUser) async {
    if (firebaseUser == null) {
      _setUser(null);
      _setLoading(false);
      return;
    }

    try {
      final user = await _authService.hydrateUser(firebaseUser);

      if (_currentUser?.uid != user.uid) {
        _setUser(user);
        // Check inactivity on login/app start
        await _checkInactivity(user.uid);
      }

    } on AuthFailure catch (failure) {
      _setError(failure.message);
    } catch (_) {
      _setError('Unable to refresh session. Please try again');
    } finally {
      _setLoading(false);
    }
  }

  /// =========================
  /// INACTIVITY CHECK
  /// =========================
  Future<void> _checkInactivity(String uid) async {
    try {
      final isInactive = await _authService.isInactiveForDays(uid, 5);
      if (isInactive) {
        await _notificationService.showInactivityNotification();
      }
    } catch (_) {
      // Silently fail for inactivity check
    }
  }
  void _setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}