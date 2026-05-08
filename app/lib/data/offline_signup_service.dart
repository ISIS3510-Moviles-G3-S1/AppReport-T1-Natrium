import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/auth_failure.dart';

/// Servicio para manejar registro offline con eventual consistency.
///
/// Cuando el usuario intenta registrarse sin conexión:
/// 1. Guarda email + password en SharedPreferences
/// 2. Muestra mensaje "Registration queued"
/// 3. Cuando vuelve la conexión, intenta sincronizar
/// 4. Si falla, reinenta automáticamente en next app open
class OfflineSignupService {
  static const String _prefEmail = 'pending_signup_email';
  static const String _prefPassword = 'pending_signup_password';
  static const String _prefDisplayName = 'pending_signup_displayName';

  /// Guarda credenciales de registro para sincronización posterior.
  static Future<void> savePendingSignUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefEmail, email);
      await prefs.setString(_prefPassword, password);
      await prefs.setString(_prefDisplayName, displayName);
      debugPrint(
        '[OfflineSignupService] Saved pending signup for $email '
        '(will sync when connection restored)',
      );
    } catch (e) {
      debugPrint('[OfflineSignupService] savePendingSignUp failed: $e');
      throw AuthFailure('Could not save registration offline.');
    }
  }

  /// Obtiene el registro pendiente si existe.
  static Future<Map<String, String>?> getPendingSignUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_prefEmail);
      final password = prefs.getString(_prefPassword);
      final displayName = prefs.getString(_prefDisplayName);

      if (email == null || password == null) return null;

      return {
        'email': email,
        'password': password,
        'displayName': displayName ?? '',
      };
    } catch (e) {
      debugPrint('[OfflineSignupService] getPendingSignUp failed: $e');
      return null;
    }
  }

  /// Limpia el registro pendiente (llamar después de sincronización exitosa).
  static Future<void> clearPendingSignUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefPassword);
      await prefs.remove(_prefDisplayName);
      debugPrint('[OfflineSignupService] Cleared pending signup');
    } catch (e) {
      debugPrint('[OfflineSignupService] clearPendingSignUp failed: $e');
    }
  }
}
