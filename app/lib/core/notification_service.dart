abstract class NotificationService {
  factory NotificationService() => const DummyNotificationService();

  Future<void> initialize();
  Future<void> showInactivityNotification();
}

class DummyNotificationService implements NotificationService {
  const DummyNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showInactivityNotification() async {}
}