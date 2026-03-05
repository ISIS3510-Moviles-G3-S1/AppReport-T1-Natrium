import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_market/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const UniMarketApp());
    // Avoid pumpAndSettle here: the app has ongoing animations/image loading
    // that can keep the scheduler busy during tests.
    await tester.pump(const Duration(milliseconds: 200));

    // Home screen headline exists.
    expect(find.textContaining('Your Campus'), findsOneWidget);
  });
}
