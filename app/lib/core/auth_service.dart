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
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _hydrateUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } catch (_) {
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

      // Update in Firestore
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Save to local SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
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
      // Try to get lastLogin from SharedPreferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      final lastLoginStr = prefs.getString('lastLogin_$uid');

      DateTime? lastLogin;

      if (lastLoginStr != null) {
        lastLogin = DateTime.parse(lastLoginStr);
      } else {
        // Fallback: fetch from Firestore
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data() ?? <String, dynamic>{};
          final timestamp = data['lastLogin'];
          if (timestamp is Timestamp) {
            lastLogin = timestamp.toDate();
          }
        }
      }

      // If no lastLogin found, user is not inactive (first login)
      if (lastLogin == null) {
        debugPrint('[AuthService] No lastLogin found for user $uid');
        return false;
      }

      // Check if user is inactive
      final now = DateTime.now();
      final daysSinceLogin = now.difference(lastLogin).inDays;
      final isInactive = daysSinceLogin >= days;

      debugPrint(
          '[AuthService] User $uid - Days since login: $daysSinceLogin (Inactive: $isInactive)');

      return isInactive;
    } catch (e) {
      debugPrint('[AuthService] Error checking inactivity: $e');
      return false;
    }
  }
}

