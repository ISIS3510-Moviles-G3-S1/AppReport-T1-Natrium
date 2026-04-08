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

  // ---------------------------------------------------------------------------
  // Type-1 Business Question: Automatic theme switching by time-of-day
  // ---------------------------------------------------------------------------

  /// Fired when the app AUTOMATICALLY switches theme based on time-of-day context.
  /// 
  /// This captures automatic theme transitions (e.g., light → dark at 7 PM,
  /// or dark → light at 6 AM) driven by the DayThemeStrategy / NightThemeStrategy
  /// polling mechanism.
  ///
  /// Use this event to answer: "What percentage of UniMarket sessions
  /// automatically switch between light and dark mode based on time-of-day context?"
  static AnalyticsEvent themeAutoSwitched({
    required String sessionId,           // Session ID for grouping
    String? userId,                      // User ID if authenticated (may be null for guests)
    required String fromTheme,           // "light" | "dark"
    required String toTheme,             // "light" | "dark"
    required int hourOfDay,              // 0-23: hour when switch occurred
    required String timestamp,           // ISO-8601: exact moment of switch
    String switchReason = 'time_based',  // "time_based" for automatic, "manual" for overrides
  }) =>
      AnalyticsEvent(
        name: 'theme_auto_switched',
        parameters: {
          'session_id': AnalyticsValue.string(sessionId),
          if (userId != null) 'user_id': AnalyticsValue.string(userId),
          'from_theme': AnalyticsValue.string(fromTheme),
          'to_theme': AnalyticsValue.string(toTheme),
          'hour_of_day': AnalyticsValue.int(hourOfDay),
          'timestamp': AnalyticsValue.string(timestamp),
          'switch_reason': AnalyticsValue.string(switchReason),
          'is_automatic': AnalyticsValue.boolType(true),
        },
      );

  /// Fired when a user manually overrides the automatic theme selection.
  ///
  /// Captures manual theme changes triggered by user preference, accessibility
  /// settings, or ambient-light detection (if implemented in future).
  static AnalyticsEvent themeManualOverride({
    required String sessionId,              // Session ID for grouping
    String? userId,                         // User ID if authenticated (may be null for guests)
    required String fromTheme,              // "light" | "dark" (the auto-selected theme before override)
    required String toTheme,                // "light" | "dark" (user's manual selection)
    required String overrideReason,         // "user_preference" | "accessibility" | "battery_saver" | etc.
    required String timestamp,              // ISO-8601: exact moment of override
  }) =>
      AnalyticsEvent(
        name: 'theme_manual_override',
        parameters: {
          'session_id': AnalyticsValue.string(sessionId),
          if (userId != null) 'user_id': AnalyticsValue.string(userId),
          'from_theme': AnalyticsValue.string(fromTheme),
          'to_theme': AnalyticsValue.string(toTheme),
          'override_reason': AnalyticsValue.string(overrideReason),
          'timestamp': AnalyticsValue.string(timestamp),
          'is_automatic': AnalyticsValue.boolType(false),
        },
      );

  /// Fired once per session to record the initial (baseline) theme choice
  /// when the app starts.
  ///
  /// Useful for understanding:
  ///   - Which theme users see on app launch (based on time of day)
  ///   - Device-to-device distribution of light vs. dark theme starts
  static AnalyticsEvent sessionThemeInitialized({
    required String sessionId,     // Session ID for grouping
    String? userId,                // User ID if authenticated
    required String initialTheme,  // "light" | "dark"
    required int hourOfDay,        // 0-23: hour when session started
    required String timestamp,     // ISO-8601: app launch time
  }) =>
      AnalyticsEvent(
        name: 'session_theme_initialized',
        parameters: {
          'session_id': AnalyticsValue.string(sessionId),
          if (userId != null) 'user_id': AnalyticsValue.string(userId),
          'initial_theme': AnalyticsValue.string(initialTheme),
          'hour_of_day': AnalyticsValue.int(hourOfDay),
          'timestamp': AnalyticsValue.string(timestamp),
        },
      );
}
