import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  final String message;
  final String code;

  const AuthFailure(this.message, {this.code = 'unknown'});

  factory AuthFailure.fromFirebaseException(FirebaseAuthException exception) {
    return AuthFailure(
      _messageForCode(exception.code),
      code: exception.code,
    );
  }

  static String _messageForCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}
