import 'package:flutter_test/flutter_test.dart';
import 'package:uni_market/core/notification_service.dart';
import 'package:uni_market/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    // Use DummyNotificationService for testing (no real notifications)
    final notificationService = DummyNotificationService();
    
    await tester.pumpWidget(
      UniMarketApp(notificationService: notificationService),
    );
    // Avoid pumpAndSettle here: the app has ongoing animations/image loading
    // that can keep the scheduler busy during tests.
    await tester.pump(const Duration(milliseconds: 200));

    // Home screen headline exists.
    expect(find.textContaining('Your Campus'), findsOneWidget);
  });
}
