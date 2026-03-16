import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'theme_strategy.dart';

/// [Strategy Pattern] — Concrete strategy for daytime (6:01 AM – 6:59 PM).
///
/// This class is one of the interchangeable algorithms that [ThemeContext]
/// can delegate to.  It encapsulates:
///   - *Which* theme to use  → [getTheme] returns [AppTheme.lightTheme].
///   - *When* to be active   → [isActiveFor] returns `true` between 6 AM and
///     6:59 PM (hours 6–18 inclusive).
///
/// Because both responsibilities live here, changing the daytime window only
/// requires editing this file — not the context or any other strategy.
class DayThemeStrategy implements ThemeStrategy {
  // 6:00 AM (hour == 6) is the start of the daytime window.
  static const int _startHour = 6;

  // 7:00 PM (hour == 19) is the exclusive upper bound, so the daytime
  // window covers hours 6 through 18 (up to 6:59 PM).
  static const int _endHour = 19;

  /// Returns the app's light theme — warm, high-contrast colours suited
  /// for well-lit environments.
  @override
  ThemeData getTheme() => AppTheme.lightTheme;

  /// Active from 6:00 AM to 6:59 PM.
  @override
  bool isActiveFor(DateTime now) {
    final hour = now.hour;
    return hour >= _startHour && hour < _endHour;
  }
}
