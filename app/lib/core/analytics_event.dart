import 'package:flutter/foundation.dart';

/// AnalyticsValue: Represents a value for analytics parameters.
enum AnalyticsValueType { string, int, doubleType, boolType }

class AnalyticsValue {
  final dynamic value;
  final AnalyticsValueType type;

  const AnalyticsValue._(this.value, this.type);

  factory AnalyticsValue.string(String v) => AnalyticsValue._(v, AnalyticsValueType.string);
  factory AnalyticsValue.int(int v) => AnalyticsValue._(v, AnalyticsValueType.int);
  factory AnalyticsValue.doubleType(double v) => AnalyticsValue._(v, AnalyticsValueType.doubleType);
  factory AnalyticsValue.boolType(bool v) => AnalyticsValue._(v, AnalyticsValueType.boolType);

  dynamic get firebaseValue {
    switch (type) {
      case AnalyticsValueType.string:
      case AnalyticsValueType.int:
      case AnalyticsValueType.doubleType:
        return value;
      case AnalyticsValueType.boolType:
        return value ? 1 : 0;
    }
  }

  String get debugValue {
    switch (type) {
      case AnalyticsValueType.string:
        return value;
      case AnalyticsValueType.int:
        return value.toString();
      case AnalyticsValueType.doubleType:
        return value.toStringAsFixed(2);
      case AnalyticsValueType.boolType:
        return value ? 'true' : 'false';
    }
  }
}

/// AnalyticsEvent: Represents an analytics event with name and parameters.
class AnalyticsEvent {
  final String name;
  final Map<String, AnalyticsValue> parameters;

  const AnalyticsEvent({required this.name, this.parameters = const {}});

  // --- Static helpers for common events (add more as needed) ---
  static AnalyticsEvent appOpened() => AnalyticsEvent(name: 'app_opened');

  static AnalyticsEvent screenViewed(String screenName) => AnalyticsEvent(
        name: 'screen_viewed',
        parameters: {'screen_name': AnalyticsValue.string(screenName)},
      );

  static AnalyticsEvent loginAttempt(String method) => AnalyticsEvent(
        name: 'login_attempt',
        parameters: {'method': AnalyticsValue.string(method)},
      );


}
