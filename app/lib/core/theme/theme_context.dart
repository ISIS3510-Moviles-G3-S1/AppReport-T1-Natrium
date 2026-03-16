import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'theme_strategy.dart';
import 'day_theme_strategy.dart';
import 'night_theme_strategy.dart';

/// [Strategy Pattern] — Context class that owns and delegates to a [ThemeStrategy].
///
/// In the Strategy pattern the "context" is the object whose behaviour
/// varies at runtime.  Here the varying behaviour is *which theme is shown*.
/// [ThemeContext] does NOT know how to build a theme — it delegates that
/// entirely to the active [ThemeStrategy].
///
/// Responsibilities of this class:
///   1. Hold a reference to the currently active [ThemeStrategy].
///   2. Automatically pick the right strategy based on the time of day.
///   3. Poll every minute so the theme switches at the correct hour even if
///      the user keeps the app open across the 6 AM / 7 PM boundary.
///   4. Expose [setStrategy] so callers can inject a manual override
///      (user preference, ambient-light sensor, battery-saving mode, etc.)
///      without touching any other class.
///
/// Extends [ChangeNotifier] so that the Flutter widget tree is rebuilt
/// automatically whenever the active strategy changes.
///
/// --- How to extend ---
/// To add a new strategy without changing existing code:
///   1. Implement [ThemeStrategy] in a new class.
///   2. Either add it to the [strategies] list passed to the constructor
///      (for automatic time/condition-based switching), or call [setStrategy]
///      at runtime for an imperative override.
class ThemeContext extends ChangeNotifier {
  /// Ordered list of strategies evaluated for automatic switching.
  /// The first strategy whose [ThemeStrategy.isActiveFor] returns `true` wins.
  final List<ThemeStrategy> _autoStrategies;

  ThemeStrategy _currentStrategy;
  Timer? _pollingTimer;

  /// `true` while a manual strategy override is in effect.
  bool _manualOverride = false;

  /// Creates a [ThemeContext] with an optional custom [strategies] list.
  ///
  /// If [strategies] is omitted the default list is
  /// `[DayThemeStrategy(), NightThemeStrategy()]`, which covers all hours.
  ///
  /// The correct strategy for the current time is resolved immediately,
  /// and a background timer starts polling every minute.
  ThemeContext({List<ThemeStrategy>? strategies})
      : _autoStrategies = strategies ??
            [
              DayThemeStrategy(),
              NightThemeStrategy(),
            ],
        _currentStrategy = _resolve(
          strategies ?? [DayThemeStrategy(), NightThemeStrategy()],
          DateTime.now(),
        ) {
    _startPolling();
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// The [ThemeData] produced by the currently active strategy.
  ///
  /// Widgets bind to this through a [Consumer<ThemeContext>] or
  /// `context.watch<ThemeContext>().currentTheme`.
  ThemeData get currentTheme => _currentStrategy.getTheme();

  /// The strategy instance that is currently in use (useful for debugging
  /// or showing a UI indicator of which mode is active).
  ThemeStrategy get activeStrategy => _currentStrategy;

  /// Whether a manual override is currently suppressing the automatic
  /// time-based strategy selection.
  bool get isManualOverride => _manualOverride;

  /// Forces [strategy] to be the active strategy, bypassing the automatic
  /// time-based check.
  ///
  /// The polling timer is paused while an override is active so the
  /// manual choice is not silently overwritten a minute later.
  ///
  /// Example — night mode on demand:
  /// ```dart
  /// context.read<ThemeContext>().setStrategy(NightThemeStrategy());
  /// ```
  void setStrategy(ThemeStrategy strategy) {
    _manualOverride = true;
    _pollingTimer?.cancel();
    _applyStrategy(strategy);
  }

  /// Reverts to automatic time-based strategy selection and restarts
  /// the polling timer.
  void clearManualOverride() {
    _manualOverride = false;
    _autoSwitch();
    _startPolling();
  }

  /// Pauses the background polling timer.
  ///
  /// Call this in tests or when the app enters the background to avoid
  /// unnecessary work.  Resume by calling [clearManualOverride] or by
  /// creating a new [ThemeContext].
  void stopAutoSwitch() => _pollingTimer?.cancel();

  // ─── Internal helpers ─────────────────────────────────────────────────────

  /// Picks the first strategy whose [ThemeStrategy.isActiveFor] returns
  /// `true` for [now].  Falls back to the last strategy in the list if
  /// none matches (should never happen with the default list).
  static ThemeStrategy _resolve(
    List<ThemeStrategy> strategies,
    DateTime now,
  ) {
    return strategies.firstWhere(
      (s) => s.isActiveFor(now),
      orElse: () => strategies.last,
    );
  }

  /// Starts a one-minute polling timer that re-evaluates the active
  /// strategy on every tick.
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_manualOverride) _autoSwitch();
    });
  }

  /// Checks whether the active strategy should change and notifies
  /// listeners only when it actually does.
  void _autoSwitch() {
    final best = _resolve(_autoStrategies, DateTime.now());
    if (best.runtimeType != _currentStrategy.runtimeType) {
      _applyStrategy(best);
    }
  }

  /// Updates [_currentStrategy] and notifies all listeners.
  void _applyStrategy(ThemeStrategy strategy) {
    _currentStrategy = strategy;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
