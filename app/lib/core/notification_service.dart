import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class NotificationService {
  /// Initialize notification permissions and plugins
  Future<void> initialize();

  /// Request notification permissions from user
  Future<bool> requestNotificationPermission();

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
  });
}

/// Real implementation using flutter_local_notifications
class RealNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('app_icon');
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'inactivity_channel',
      'Inactivity Notifications',
      channelDescription: 'Notifications for user inactivity',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  static void _onNotificationTapped(
    NotificationResponse notificationResponse,
  ) {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }

  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('Local notification received: $title - $body');
  }
}

/// Dummy implementation for testing (no actual notifications)
class DummyNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {
    debugPrint('DummyNotificationService: initialize called');
  }

  @override
  Future<bool> requestNotificationPermission() async {
    debugPrint('DummyNotificationService: permission granted (fake)');
    return true;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('DummyNotificationService: showNotification - $title: $body');
  }
}
