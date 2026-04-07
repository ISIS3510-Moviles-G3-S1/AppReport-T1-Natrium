import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'analytics_event.dart';

abstract class AnalyticsProvider {
  void track(AnalyticsEvent event);
  void setUserId(String? userId);
  void setUserProperty(String? value, {required String name});
  void reset();
}

class FirebaseAnalyticsProvider implements AnalyticsProvider {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void track(AnalyticsEvent event) {
    _analytics.logEvent(
      name: event.name,
      parameters: event.parameters.map((k, v) => MapEntry(k, v.firebaseValue)),
    );
  }

  @override
  void setUserId(String? userId) {
    _analytics.setUserId(id: userId);
  }

  @override
  void setUserProperty(String? value, {required String name}) {
    _analytics.setUserProperty(name: name, value: value);
  }

  @override
  void reset() {
    _analytics.setUserId(id: null);
  }
}

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  final List<AnalyticsProvider> _providers;
  final bool isDebugLoggingEnabled;

  // ─── Session tracking ──────────────────────────────────────────────────────
  /// Unique identifier for the current app session (generated on-demand).
  late final String _sessionId;
  String? _currentUserId;

  AnalyticsService._({
    List<AnalyticsProvider>? providers,
    this.isDebugLoggingEnabled = true,
  }) : _providers = providers ?? [FirebaseAnalyticsProvider()] {
    _initializeSessionId();
  }

  /// Generates a unique session ID on first access (lazy initialization).
  void _initializeSessionId() {
    _sessionId = const Uuid().v4();
    if (isDebugLoggingEnabled) {
      debugPrint('[Analytics] Session initialized: $_sessionId');
    }
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns the current session ID. Unique per app launch.
  String get sessionId => _sessionId;

  /// Returns the currently authenticated user ID, or null if not authenticated.
  String? get currentUserId => _currentUserId;

  void track(AnalyticsEvent event) {
    for (final provider in _providers) {
      provider.track(event);
    }
    if (isDebugLoggingEnabled) {
      final params = event.parameters.entries
          .map((e) => '${e.key}=${e.value.debugValue}')
          .join(', ');
      if (params.isEmpty) {
        debugPrint('[Analytics] ${event.name}');
      } else {
        debugPrint('[Analytics] ${event.name} {$params}');
      }
    }
  }

  void setUserId(String? userId) {
    _currentUserId = userId;
    for (final provider in _providers) {
      provider.setUserId(userId);
    }
    if (isDebugLoggingEnabled && userId != null) {
      debugPrint('[Analytics] User ID set: $userId');
    }
  }

  void setUserProperty(String? value, {required String name}) {
    for (final provider in _providers) {
      provider.setUserProperty(value, name: name);
    }
  }

  void reset() {
    _currentUserId = null;
    for (final provider in _providers) {
      provider.reset();
    }
    if (isDebugLoggingEnabled) {
      debugPrint('[Analytics] Session reset (user logged out)');
    }
  }
}
