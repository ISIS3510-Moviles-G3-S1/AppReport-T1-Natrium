import 'package:flutter/material.dart';

/// [Strategy Pattern] — Abstract interface (the "Strategy").
///
/// In the Strategy pattern, this abstract class defines the *contract*
/// that every concrete strategy must fulfil.  The context class
/// ([ThemeContext]) holds a reference to a [ThemeStrategy] and calls
/// [getTheme] without knowing — or caring — which concrete strategy
/// it is talking to.
///
/// To add a new theme strategy (e.g., ambient-light sensor, battery-saving,
/// user-manual override), simply:
///   1. Create a new class that `implements ThemeStrategy`.
///   2. Implement [getTheme] with the desired [ThemeData].
///   3. Implement [isActiveFor] with whatever activation logic you need.
///   4. Pass an instance to [ThemeContext] — no other code changes required.
abstract class ThemeStrategy {
  /// Returns the [ThemeData] associated with this strategy.
  ///
  /// Called by [ThemeContext] every time the app needs to know the
  /// currently active theme.
  ThemeData getTheme();

  /// Returns `true` when this strategy considers itself the correct
  /// choice for [now].
  ///
  /// [ThemeContext] iterates over all registered strategies and picks
  /// the first one whose [isActiveFor] returns `true`.  Keeping this
  /// logic inside each strategy (rather than in the context) means you
  /// can change or add activation rules without touching shared code.
  bool isActiveFor(DateTime now);
}
