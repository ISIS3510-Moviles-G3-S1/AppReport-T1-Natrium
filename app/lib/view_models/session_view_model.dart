import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/auth_service.dart';
import '../models/app_user.dart';

class SessionViewModel extends ChangeNotifier {
  SessionViewModel({required AuthService authService})
      : _authService = authService {
    _authSubscription =
        _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  AppUser? _currentUser;
  bool _isLoading = true;

  // =========================
  // GETTERS
  // =========================
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // =========================
  // AUTH ACTIONS
  // =========================

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);

    await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    // ❌ NO tocar estado aquí
    // Firebase listener se encarga
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    await _authService.signIn(
      email: email,
      password: password,
    );

    // ❌ NO tocar estado aquí
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
  }

  // =========================
  // AUTH LISTENER (CORE)
  // =========================

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 🔥 1. Autenticación inmediata (NO bloquea UI)
    _currentUser = AppUser.fromFirebaseUser(firebaseUser);
    _isLoading = false;
    notifyListeners();

    // 🔄 2. Firestore en background
    _loadUserFromFirestore(firebaseUser.uid);
  }

  // =========================
  // FIRESTORE USER LOAD
  // =========================

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
        notifyListeners();
      } else {
        // 🔥 opcional: crear usuario automáticamente
        await _createUserInFirestore(uid);
      }
    } catch (e) {
      debugPrint('Firestore user load error: $e');
    }
  }

  Future<void> _createUserInFirestore(String uid) async {
    if (_currentUser == null) return;

    final user = _currentUser!;

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'profilePic': user.profilePic ?? '',
      'xpPoints': user.xpPoints ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(data);
  }

  // =========================
  // HELPERS
  // =========================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =========================
  // CLEANUP
  // =========================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}