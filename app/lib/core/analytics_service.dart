import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
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

  AnalyticsService._({
    List<AnalyticsProvider>? providers,
    this.isDebugLoggingEnabled = true,
  }) : _providers = providers ?? [FirebaseAnalyticsProvider()];

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
    for (final provider in _providers) {
      provider.setUserId(userId);
    }
  }

  void setUserProperty(String? value, {required String name}) {
    for (final provider in _providers) {
      provider.setUserProperty(value, name: name);
    }
  }

  void reset() {
    for (final provider in _providers) {
      provider.reset();
    }
  }
}
