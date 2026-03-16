import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'theme_strategy.dart';

/// [Strategy Pattern] — Concrete strategy for nighttime (7:00 PM – 5:59 AM).
///
/// Mirror counterpart to [DayThemeStrategy].  It encapsulates:
///   - *Which* theme to use  → [getTheme] returns [AppTheme.darkTheme].
///   - *When* to be active   → [isActiveFor] returns `true` from 7:00 PM
///     (hour >= 19) up to and including 5:59 AM (hour < 6).
///
/// The nighttime window wraps around midnight, so the check uses an
/// OR condition rather than a range comparison.
class NightThemeStrategy implements ThemeStrategy {
  // 7:00 PM — start of the night window (going forward in the day).
  static const int _nightStartHour = 19;

  // 6:00 AM — end of the night window (the morning boundary).
  static const int _morningEndHour = 6;

  /// Returns the app's dark theme — reduced brightness, muted tones, and
  /// lower contrast suited for low-light environments.
  @override
  ThemeData getTheme() => AppTheme.darkTheme;

  /// Active from 7:00 PM to 5:59 AM (wraps around midnight).
  @override
  bool isActiveFor(DateTime now) {
    final hour = now.hour;
    return hour >= _nightStartHour || hour < _morningEndHour;
  }
}
