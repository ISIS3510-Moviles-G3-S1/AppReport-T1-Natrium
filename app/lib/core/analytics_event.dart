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

  // ---------------------------------------------------------------------------
  // Type-2 Business Question: User inactivity & engagement timing
  // ---------------------------------------------------------------------------

  /// Fired on every meaningful user interaction (buy, like, sell).
  static AnalyticsEvent userMeaningfulInteraction({
    required String userId,
    required String interactionType, // "buy" | "like" | "sell" | "view"
    required String timestamp,       // ISO-8601
    required String category,        // Category/tag of the item
  }) =>
      AnalyticsEvent(
        name: 'user_meaningful_interaction',
        parameters: {
          'user_id': AnalyticsValue.string(userId),
          'interaction_type': AnalyticsValue.string(interactionType),
          'timestamp': AnalyticsValue.string(timestamp),
          'category': AnalyticsValue.string(category),
        },
      );

  /// Fired when a new item is uploaded (for category new item count).
  static AnalyticsEvent newItemUploaded({
    required String userId,         // Seller's user id
    required String category,       // Category/tag of the item
    required String timestamp,      // ISO-8601
  }) =>
      AnalyticsEvent(
        name: 'new_item_uploaded',
        parameters: {
          'user_id': AnalyticsValue.string(userId),
          'category': AnalyticsValue.string(category),
          'timestamp': AnalyticsValue.string(timestamp),
        },
      );

  /// Fired every time the app evaluates whether the user is inactive.
  static AnalyticsEvent userInactivityChecked({
    required String userId,
    required int daysSinceLastInteraction,
    required bool isInactive,
    required int thresholdDays,
  }) =>
      AnalyticsEvent(
        name: 'user_inactivity_checked',
        parameters: {
          'user_id': AnalyticsValue.string(userId),
          'days_since_last_interaction': AnalyticsValue.int(daysSinceLastInteraction),
          'is_inactive': AnalyticsValue.boolType(isInactive),
          'threshold_days': AnalyticsValue.int(thresholdDays),
        },
      );

  /// Fired ONLY when a re-engagement notification is actually triggered.
  static AnalyticsEvent reengagementNotificationTriggered({
    required String userId,
    required int daysInactive,
    required int thresholdDays,
    String notificationType = 'inactivity_nudge',
  }) =>
      AnalyticsEvent(
        name: 'reengagement_notification_triggered',
        parameters: {
          'user_id': AnalyticsValue.string(userId),
          'days_inactive': AnalyticsValue.int(daysInactive),
          'threshold_days': AnalyticsValue.int(thresholdDays),
          'notification_type': AnalyticsValue.string(notificationType),
        },
      );

  /// Fired when the inactivity check passes (user is active — no notification sent).
  static AnalyticsEvent userActiveNoNotification({
    required String userId,
    required int daysSinceLastInteraction,
  }) =>
      AnalyticsEvent(
        name: 'user_active_no_notification',
        parameters: {
          'user_id': AnalyticsValue.string(userId),
          'days_since_last_interaction': AnalyticsValue.int(daysSinceLastInteraction),
        },
      );
}
