import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      final user = await _hydrateUser(credential.user!);
      await _updateLastLogin(user.uid);
      return user;
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
    });

    final createdDoc = await docRef.get();
    if (createdDoc.exists) {
      return AppUser.fromFirestore(createdDoc);
    }

    return AppUser.fromFirebaseUser(firebaseUser);
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<DateTime?> getLastLogin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      final timestamp = data?['lastLogin'] as Timestamp?;
      return timestamp?.toDate();
    }
    return null;
  }

  int? daysSinceLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return null;
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    return difference.inDays;
  }

  Future<bool> isInactiveForDays(String uid, int days) async {
    final lastLogin = await getLastLogin(uid);
    final daysSince = daysSinceLastLogin(lastLogin);
    return daysSince != null && daysSince > days;
  }
}
