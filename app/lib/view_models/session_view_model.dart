import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../core/auth_failure.dart';
import '../core/lru_cache.dart';
import '../core/notification_service.dart';
import '../data/listing_service.dart';
import '../models/app_user.dart';

class SessionViewModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  StreamSubscription<User?>? _authSubscription;

  // â”€â”€ LRU profile cache â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Capacity 50: covers the logged-in user + seller profiles viewed in a
  // typical session. get() promotes to MRU; put() evicts the LRU head on
  // overflow. Declared static so the cache survives ViewModel recreation.
  static final LruCache<String, AppUser> _profileCache =
      LruCache<String, AppUser>(capacity: 50);

  // â”€â”€ SharedPreferences keys â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String _prefUid = 'auth_cached_uid';
  static const String _prefEmail = 'auth_cached_email';
  static const String _prefDisplayName = 'auth_cached_displayName';
  static const String _prefProfilePic = 'auth_cached_profilePic';
  static const String _prefXp = 'auth_cached_xpPoints';

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SessionViewModel({
    required NotificationService notificationService,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService {
    _forceLogoutOnStart();
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthState,
      onError: (_, __) {
        _setError('Session error. Please try again');
        _setLoading(false);
      },
    );
  }

  Future<void> _forceLogoutOnStart() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) _profileCache.invalidate(uid);
      await _clearPersistedUser();
      await _auth.signOut();
      _setUser(null);
    } catch (_) {}
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SIGN IN
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[SessionViewModel] signIn email=$email');
    _setLoading(true);
    _setError(null);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await _hydrateUser(credential.user!);

      final isInactive = await _isInactiveForDays(user.uid, days: 3);
      if (isInactive) {
        await _notificationService.showNotification(
          title: 'We miss you!',
          body: 'There are new items waiting for you!',
        );
      }
      await _checkPostInactivityAndNotify(user.uid);
      await _updateLastLogin(user.uid);
      _setUser(user);
    } on FirebaseAuthException catch (e) {
      debugPrint('[SessionViewModel] FirebaseAuthException code=${e.code}');
      final failure = AuthFailure.fromFirebaseException(e);
      _setError(failure.message);
      throw failure;
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SIGN UP
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user!;
      if (displayName != null && displayName.trim().isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName.trim());
      }

      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      await docRef.set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'displayName': displayName ??
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            '',
        'profilePic': firebaseUser.photoURL ?? '',
        'xpPoints': 0,
        'isVerified': false,
        'numTransactions': 0,
        'ratingStars': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      final user = AppUser.fromFirestore(doc);
      _profileCache.put(user.uid, user);
      await _persistUserToPrefs(user);
      _setUser(user);
    } on FirebaseAuthException catch (e) {
      final failure = AuthFailure.fromFirebaseException(e);
      _setError(failure.message);
      throw failure;
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // SIGN OUT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _profileCache.invalidate(uid);
        debugPrint('[SessionViewModel] LRU cache invalidated uid=$uid');
      }
      // Intentionally do NOT clear SharedPreferences here.
      // Keeping the last session in prefs allows offline login to restore it
      // after the user has signed out and lost connectivity.
      // Prefs are overwritten on the next successful online sign-in/sign-up.
      await _auth.signOut();
      _setUser(null);
    } on FirebaseAuthException catch (e) {
      final failure = AuthFailure.fromFirebaseException(e);
      _setError(failure.message);
      throw failure;
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PUBLIC CACHE ACCESS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Restores the last session from SharedPreferences and warms the LRU cache.
  /// Use when the device is offline and no Firebase call can be made.
  /// Throws [AuthFailure] with code 'no-cached-user' if no persisted session
  /// is found (i.e. the user has never logged in on this device before).
  Future<void> signInOffline() async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await getCachedSessionUser();
      if (user == null) {
        throw const AuthFailure(
          'No saved session found. Please connect to the internet and log in.',
          code: 'no-cached-user',
        );
      }
      _setUser(user);
      debugPrint('[SessionViewModel] signInOffline restored uid=${user.uid}');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      const failure = AuthFailure('Offline login failed. Please try again.');
      _setError(failure.message);
      throw failure;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns the AppUser persisted in SharedPreferences from the last session.
  Future<AppUser?> getCachedSessionUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_prefUid);
      if (uid == null || uid.isEmpty) return null;
      final user = AppUser(
        uid: uid,
        email: prefs.getString(_prefEmail) ?? '',
        displayName: prefs.getString(_prefDisplayName) ?? '',
        profilePic: prefs.getString(_prefProfilePic) ?? '',
        xpPoints: prefs.getInt(_prefXp) ?? 0,
      );
      _profileCache.put(uid, user);
      debugPrint('[SessionViewModel] getCachedSessionUser uid=$uid');
      return user;
    } catch (e) {
      debugPrint('[SessionViewModel] getCachedSessionUser failed: $e');
      return null;
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // INACTIVITY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<bool> checkInactivity({int days = 3}) async {
    if (_currentUser == null) return false;
    return _isInactiveForDays(_currentUser!.uid, days: days);
  }

  Future<void> checkPostInactivityAndNotify() async {
    if (_currentUser == null) return;
    await _checkPostInactivityAndNotify(_currentUser!.uid);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // PRIVATE â€” user hydration with LRU + SharedPreferences
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<AppUser> _hydrateUser(User firebaseUser) async {
    final cached = _profileCache.get(firebaseUser.uid);
    if (cached != null) {
      debugPrint('[SessionViewModel] _hydrateUser LRU HIT uid=${firebaseUser.uid}');
      return cached;
    }
    debugPrint('[SessionViewModel] _hydrateUser LRU MISS â€” fetching Firestore');

    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      AppUser user = AppUser.fromFirestore(doc);
      if (user.profilePic.trim().isEmpty) {
        final authPhoto = firebaseUser.photoURL ?? '';
        if (authPhoto.trim().isNotEmpty) user = user.copyWith(profilePic: authPhoto);
      }
      _profileCache.put(user.uid, user);
      await _persistUserToPrefs(user);
      return user;
    }

    await docRef.set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'displayName':
          firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? '',
      'profilePic': firebaseUser.photoURL ?? '',
      'xpPoints': 0,
      'isVerified': false,
      'numTransactions': 0,
      'ratingStars': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });

    final createdDoc = await docRef.get();
    final user = createdDoc.exists
        ? AppUser.fromFirestore(createdDoc)
        : AppUser.fromFirebaseUser(firebaseUser);
    _profileCache.put(user.uid, user);
    await _persistUserToPrefs(user);
    return user;
  }

  Future<void> _persistUserToPrefs(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUid, user.uid);
      await prefs.setString(_prefEmail, user.email);
      await prefs.setString(_prefDisplayName, user.displayName);
      await prefs.setString(_prefProfilePic, user.profilePic);
      await prefs.setInt(_prefXp, user.xpPoints);
    } catch (e) {
      debugPrint('[SessionViewModel] _persistUserToPrefs failed: $e');
    }
  }

  Future<void> _clearPersistedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUid);
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefDisplayName);
      await prefs.remove(_prefProfilePic);
      await prefs.remove(_prefXp);
    } catch (e) {
      debugPrint('[SessionViewModel] _clearPersistedUser failed: $e');
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      DateTime? existingLastLogin;
      if (doc.exists) {
        final ts = (doc.data() ?? {})['lastLogin'];
        if (ts is Timestamp) existingLastLogin = ts.toDate();
      }

      final updateData = <String, Object>{'lastLogin': FieldValue.serverTimestamp()};
      if (existingLastLogin != null) updateData['previousLogin'] = existingLastLogin;
      await docRef.update(updateData);

      final prefs = await SharedPreferences.getInstance();
      if (existingLastLogin != null) {
        await prefs.setString('previousLogin_$uid', existingLastLogin.toIso8601String());
      }
      await prefs.setString('lastLogin_$uid', now.toIso8601String());
    } catch (e) {
      debugPrint('[SessionViewModel] _updateLastLogin failed: $e');
    }
  }

  Future<bool> _isInactiveForDays(String uid, {int days = 3}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      DateTime? previousLogin =
          DateTime.tryParse(prefs.getString('previousLogin_$uid') ?? '');

      if (previousLogin == null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final ts = (doc.data() ?? {})['previousLogin'];
          if (ts is Timestamp) previousLogin = ts.toDate();
        }
      }

      if (previousLogin == null) return false;

      final daysSince = DateTime.now().difference(previousLogin).inDays;
      final isInactive = daysSince >= days;

      AnalyticsService.instance.track(
        AnalyticsEvent.userInactivityChecked(
          userId: uid,
          daysSinceLastInteraction: daysSince,
          isInactive: isInactive,
          thresholdDays: days,
        ),
      );
      if (isInactive) {
        AnalyticsService.instance.track(
          AnalyticsEvent.reengagementNotificationTriggered(
            userId: uid,
            daysInactive: daysSince,
            thresholdDays: days,
          ),
        );
      } else {
        AnalyticsService.instance.track(
          AnalyticsEvent.userActiveNoNotification(
            userId: uid,
            daysSinceLastInteraction: daysSince,
          ),
        );
      }
      return isInactive;
    } catch (e) {
      debugPrint('[SessionViewModel] _isInactiveForDays failed: $e');
      return false;
    }
  }

  Future<void> _checkPostInactivityAndNotify(String uid) async {
    try {
      final lastPostDate = await ListingService().getLastPostDate(uid);
      if (lastPostDate == null) {
        await _notificationService.showNotification(
          title: 'Upload your first!',
          body: 'You haven\'t posted any items yet.',
        );
        return;
      }
      final daysSince = DateTime.now().difference(lastPostDate).inDays;
      if (daysSince >= 15) {
        await _notificationService.showNotification(
          title: 'It\'s been a while!',
          body: 'It\'s been more than $daysSince days since your last post.',
        );
      }
    } catch (e) {
      debugPrint('[SessionViewModel] _checkPostInactivityAndNotify failed: $e');
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // AUTH STATE LISTENER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _handleAuthState(User? firebaseUser) async {
    if (firebaseUser == null) {
      _setUser(null);
      _setLoading(false);
      return;
    }
    try {
      final user = await _hydrateUser(firebaseUser);
      if (_currentUser?.uid != user.uid) _setUser(user);
    } on AuthFailure catch (failure) {
      _setError(failure.message);
    } catch (_) {
      _setError('Unable to refresh session');
    } finally {
      _setLoading(false);
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // HELPERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _setUser(AppUser? user) {
    _currentUser = user;
    if (user != null) {
      AnalyticsService.instance.setUserId(user.uid);
    } else {
      AnalyticsService.instance.reset();
    }
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
