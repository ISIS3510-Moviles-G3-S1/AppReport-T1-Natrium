import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_market/core/theme/day_theme_strategy.dart';
import 'package:uni_market/core/theme/night_theme_strategy.dart';
import 'package:uni_market/core/theme/theme_context.dart';

 
DateTime _at(int hour) => DateTime(2024, 1, 15, hour, 0, 0);

void main() {

  group('DayThemeStrategy', () {
    final strategy = DayThemeStrategy();

    // Boundary: exactly 6:00 AM — first minute of daytime.
    test('is active at 6:00 AM (boundary start)', () {
      expect(strategy.isActiveFor(_at(6)), isTrue);
    });

    // Mid-day hour.
    test('is active at 12:00 PM (noon)', () {
      expect(strategy.isActiveFor(_at(12)), isTrue);
    });

    // Last valid daytime hour: 6:59 PM (hour == 18).
    test('is active at 6:00 PM (last daytime hour)', () {
      expect(strategy.isActiveFor(_at(18)), isTrue);
    });

    // 7:00 PM belongs to night — should NOT be active.
    test('is NOT active at 7:00 PM (boundary end, exclusive)', () {
      expect(strategy.isActiveFor(_at(19)), isFalse);
    });

    // Deep-night hour.
    test('is NOT active at midnight', () {
      expect(strategy.isActiveFor(_at(0)), isFalse);
    });

    // Returns a light-brightness theme.
    test('getTheme returns a light ThemeData', () {
      expect(strategy.getTheme().brightness, Brightness.light);
    });
  });


  group('NightThemeStrategy', () {
    final strategy = NightThemeStrategy();

    // Boundary: exactly 7:00 PM — first minute of nighttime.
    test('is active at 7:00 PM (boundary start)', () {
      expect(strategy.isActiveFor(_at(19)), isTrue);
    });

    // Deep-night hour.
    test('is active at midnight', () {
      expect(strategy.isActiveFor(_at(0)), isTrue);
    });

    // Early morning — still nighttime until 6 AM.
    test('is active at 5:00 AM', () {
      expect(strategy.isActiveFor(_at(5)), isTrue);
    });

    // 6:00 AM is the morning boundary — night ends here.
    test('is NOT active at 6:00 AM (boundary end, exclusive)', () {
      expect(strategy.isActiveFor(_at(6)), isFalse);
    });

    // Mid-day should not trigger night mode.
    test('is NOT active at noon', () {
      expect(strategy.isActiveFor(_at(12)), isFalse);
    });

    // Returns a dark-brightness theme.
    test('getTheme returns a dark ThemeData', () {
      expect(strategy.getTheme().brightness, Brightness.dark);
    });
  });


  group('ThemeContext automatic selection', () {

    test('selects DayThemeStrategy during the day', () {
      final strategies = [DayThemeStrategy(), NightThemeStrategy()];
      final now = _at(10); // 10:00 AM
      final winner =
          strategies.firstWhere((s) => s.isActiveFor(now));
      expect(winner, isA<DayThemeStrategy>());
    });

    test('selects NightThemeStrategy at night', () {
      final strategies = [DayThemeStrategy(), NightThemeStrategy()];
      final now = _at(22); // 10:00 PM
      final winner =
          strategies.firstWhere((s) => s.isActiveFor(now));
      expect(winner, isA<NightThemeStrategy>());
    });

    test('selects NightThemeStrategy before dawn (3:00 AM)', () {
      final strategies = [DayThemeStrategy(), NightThemeStrategy()];
      final now = _at(3);
      final winner =
          strategies.firstWhere((s) => s.isActiveFor(now));
      expect(winner, isA<NightThemeStrategy>());
    });
  });


  group('ThemeContext manual override', () {
    test('setStrategy overrides automatic selection', () {
      final ctx = ThemeContext();

      ctx.setStrategy(NightThemeStrategy());

      expect(ctx.isManualOverride, isTrue);
      expect(ctx.currentTheme.brightness, Brightness.dark);

      ctx.dispose();
    });

    test('clearManualOverride reverts to automatic selection', () {
      final ctx = ThemeContext();

      ctx.setStrategy(NightThemeStrategy());
      ctx.clearManualOverride();

      expect(ctx.isManualOverride, isFalse);
      
      expect(ctx.currentTheme, isA<ThemeData>());

      ctx.dispose();
    });

    test('setStrategy notifies listeners', () {
      final ctx = ThemeContext();
      var notified = false;
      ctx.addListener(() => notified = true);

      ctx.setStrategy(DayThemeStrategy());

      expect(notified, isTrue);
      ctx.dispose();
    });
  });
}
