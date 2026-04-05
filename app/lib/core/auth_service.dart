import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'auth_failure.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // For testing: simulate auth failure
    if (email == "test@error.com") {
      throw const AuthFailure('Invalid credentials', code: 'invalid-credential');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _hydrateUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } catch (e) {
      throw const AuthFailure('Unable to sign in. Please try again');
    }
  }

  Future<AppUser> signUp({
  required String email,
  required String password,
  String? displayName,
}) async {
  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    if (displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }

    final docRef = _firestore.collection('users').doc(user.uid);

    await docRef.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': displayName ??
          user.displayName ??
          user.email?.split('@').first ??
          '',
      'profilePic': user.photoURL ?? '',
      'xpPoints': 0,
      'isVerified': false,
      'numTransactions': 0,
      'ratingStars': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
    
    final doc = await docRef.get();
    return AppUser.fromFirestore(doc);

  } on FirebaseAuthException catch (e) {
    throw AuthFailure.fromFirebaseException(e);
  } catch (e) {
    throw const AuthFailure('Unable to sign up. Please try again');
  }
}

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } catch (_) {
      throw const AuthFailure('Unable to sign out. Please try again');
    }
  }

  Future<AppUser> hydrateUser(User firebaseUser) {
    return _hydrateUser(firebaseUser);
  }

  Future<AppUser> _hydrateUser(
    User firebaseUser, {
    String? overrideDisplayName,
  }) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }

    await docRef.set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'displayName': overrideDisplayName ??
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

    final createdDoc = await docRef.get();
    if (createdDoc.exists) {
      return AppUser.fromFirestore(createdDoc);
    }

    return AppUser.fromFirebaseUser(firebaseUser);
  }

  /// Update lastLogin timestamp for user in Firestore and SharedPreferences
  Future<void> updateLastLogin(String uid) async {
    try {
      final now = DateTime.now();

      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      DateTime? existingLastLogin;
      if (doc.exists) {
        final data = doc.data() ?? <String, dynamic>{};
        final existingTimestamp = data['lastLogin'];
        if (existingTimestamp is Timestamp) {
          existingLastLogin = existingTimestamp.toDate();
        }
      }

      final updateData = <String, Object>{
        'lastLogin': FieldValue.serverTimestamp(),
      };
      if (existingLastLogin != null) {
        updateData['previousLogin'] = existingLastLogin;
      }

      await docRef.update(updateData);

      // Save to local SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      if (existingLastLogin != null) {
        await prefs.setString('previousLogin_$uid', existingLastLogin.toIso8601String());
      }
      await prefs.setString('lastLogin_$uid', now.toIso8601String());

      debugPrint('[AuthService] Updated lastLogin for user $uid');
    } catch (e) {
      debugPrint('[AuthService] Error updating lastLogin: $e');
    }
  }

  /// Check if user is inactive for specified number of days
  /// Returns true if user hasn't logged in for >= days
  Future<bool> isInactiveForDays(String uid, {int days = 3}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previousLoginStr = prefs.getString('previousLogin_$uid');
      final lastLoginStr = prefs.getString('lastLogin_$uid');

      DateTime? previousLogin;
      DateTime? lastLogin;

      if (previousLoginStr != null) {
        previousLogin = DateTime.tryParse(previousLoginStr);
      }

      if (lastLoginStr != null) {
        lastLogin = DateTime.tryParse(lastLoginStr);
      }

      if (previousLogin == null) {
        // Need a previous login to evaluate inactivity across sessions.
        // Try to load from Firestore.
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() ?? <String, dynamic>{};
          final tsPrev = data['previousLogin'];
          final tsLast = data['lastLogin'];
          if (tsPrev is Timestamp) {
            previousLogin = tsPrev.toDate();
          }
          if (tsLast is Timestamp) {
            lastLogin ??= tsLast.toDate();
          }
        }
      }

      if (previousLogin == null) {
        debugPrint('[AuthService] No previousLogin found for user $uid');
        return false;
      }

      final now = DateTime.now();
      final daysSincePreviousLogin = now.difference(previousLogin).inDays;
      final isInactive = daysSincePreviousLogin >= days;

      debugPrint(
        '[AuthService] User $uid - Days since previous login: $daysSincePreviousLogin (Inactive: $isInactive)',
      );

      return isInactive;
    } catch (e) {
      debugPrint('[AuthService] Error checking inactivity: $e');
      return false;
    }
  }
}

