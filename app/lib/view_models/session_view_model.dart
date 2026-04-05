import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_failure.dart';
import '../core/auth_service.dart';
import '../core/notification_service.dart';
import '../models/app_user.dart';
import '../data/listing_service.dart';

class SessionViewModel extends ChangeNotifier {
    /// Notifica si el usuario lleva más de 15 días sin hacer un post o nunca ha hecho un post
    Future<void> checkPostInactivityAndNotify() async {
      if (currentUser == null) return;
      final lastPostDate = await ListingService().getLastPostDate(currentUser!.uid);
      if (lastPostDate == null) {
        await _notificationService.showNotification(
          title: '¡Publica tu primer artículo!',
          body: 'Aún no has publicado ningún artículo. ¡Anímate a publicar tu primer artículo hoy!',
        );
        return;
      }

      final daysSinceLastPost = DateTime.now().difference(lastPostDate).inDays;
      if (daysSinceLastPost >= 15) {
        await _notificationService.showNotification(
          title: '¡Te extrañamos!',
          body: 'Hace más de $daysSinceLastPost días que no publicas un artículo. ¡Publica uno nuevo hoy!',
        );
      }
    }
  SessionViewModel({
    required AuthService authService,
    required NotificationService notificationService,
  })  : _authService = authService,
        _notificationService = notificationService {
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

      // Notifica si lleva más de 3 días sin iniciar sesión
      final isInactive = await checkInactivity(days: 3);
      if (isInactive) {
        await _notificationService.showNotification(
          title: '¡Te extrañamos!',
          body: 'Hace más de 3 días que no inicias sesión. ¡Vuelve a UniMarket!',
        );
      }

      // Notifica si lleva más de 15 días sin postear
      await checkPostInactivityAndNotify();

      // Update lastLogin timestamp
      await _authService.updateLastLogin(user.uid);

      _setUser(user);
    } on AuthFailure catch (failure) {
      _setError(failure.message);
      rethrow;
    } catch (e) {
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
  /// INACTIVITY CHECK
  /// =========================
  Future<bool> checkInactivity({int days = 3}) async {
    if (currentUser == null) return false;

    try {
      return await _authService.isInactiveForDays(currentUser!.uid, days: days);
    } catch (e) {
      debugPrint('Error checking inactivity: $e');
      return false;
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
  /// STATE HELPERS
  /// =========================
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