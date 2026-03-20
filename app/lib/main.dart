import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'core/app_router.dart';
import 'core/auth_service.dart';
import 'core/notification_service.dart';
import 'core/theme/theme_context.dart';
import 'view_models/browse_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/sell_view_model.dart';
import 'view_models/session_view_model.dart';

class RealNotificationService implements NotificationService {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Future<void> showInactivityNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'inactivity_channel',
      'Inactivity Notifications',
      channelDescription: 'Notifications for user inactivity',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Welcome back!',
      'It\'s been a while since your last visit. Check out new listings!',
      platformChannelSpecifics,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  final notificationService = RealNotificationService();
  await notificationService.initialize();

  runApp(UniMarketApp(notificationService: notificationService));
}

class UniMarketApp extends StatelessWidget {
  const UniMarketApp({super.key, this.notificationService});

  final NotificationService? notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeContext()),

        Provider(create: (_) => AuthService()),

        if (notificationService != null)
          Provider<NotificationService>.value(value: notificationService!),

        ChangeNotifierProvider(
          create: (context) => SessionViewModel(
            authService: context.read<AuthService>(),
            notificationService: notificationService,
          ),
        ),

        ChangeNotifierProxyProvider<SessionViewModel, ProfileViewModel>(
          create: (context) =>
              ProfileViewModel(context.read<SessionViewModel>()),
          update: (_, session, previous) =>
              previous ?? ProfileViewModel(session),
        ),

        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => BrowseViewModel()),
        ChangeNotifierProvider(create: (_) => SellViewModel()),

        ProxyProvider<SessionViewModel, GoRouter>(
          update: (_, session, __) => createAppRouter(session),
        ),
      ],
      child: Consumer2<ThemeContext, GoRouter>(
        builder: (context, themeCtx, router, _) => MaterialApp.router(
          title: 'UniMarket',
          theme: themeCtx.currentTheme,
          routerConfig: router,
        ),
      ),
    );
  }
}