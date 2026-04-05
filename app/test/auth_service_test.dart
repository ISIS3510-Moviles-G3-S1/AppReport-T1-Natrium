import 'package:flutter_test/flutter_test.dart';
import 'package:uni_market/core/auth_failure.dart';
import 'package:uni_market/core/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('signIn throws AuthFailure for test error email', () async {
      expect(
        () => authService.signIn(
          email: 'test@error.com',
          password: 'password',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('AuthFailure has correct message for invalid-credential', () {
      const failure = AuthFailure('Invalid credentials', code: 'invalid-credential');
      expect(failure.message, 'Invalid credentials');
      expect(failure.code, 'invalid-credential');
    });
  });
}