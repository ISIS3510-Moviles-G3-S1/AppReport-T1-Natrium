import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'core/analytics_service.dart';
import 'core/app_router.dart';
import 'core/notification_service.dart';
import 'core/lru_cache_service.dart';
import 'core/theme/theme_context.dart';
import 'view_models/browse_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/seller_performance_view_model.dart';
import 'view_models/sell_view_model.dart';
import 'view_models/session_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<dynamic>('listing_drafts_v1');
  await Hive.openBox<dynamic>('browse_view_model');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize analytics service
  debugPrint('[Main] Analytics Service initialized. Session ID: ${AnalyticsService.instance.sessionId}');

  // Initialize notification service
  final notificationService = RealNotificationService();
  await notificationService.initialize();
  final permissionGranted = await notificationService.requestNotificationPermission();
  debugPrint('[Main] Notification permission granted: $permissionGranted');

  final areGranted = await notificationService.arePermissionsGranted();
  debugPrint('[Main] Notification permissions are granted: $areGranted');

  runApp(UniMarketApp(notificationService: notificationService));
}

class UniMarketApp extends StatelessWidget {
  final NotificationService notificationService;

  const UniMarketApp({
    super.key,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeContext()),

        Provider<NotificationService>(create: (_) => notificationService),

        ChangeNotifierProvider(
          create: (context) => SessionViewModel(
            notificationService: context.read<NotificationService>(),
          ),
        ),

        ChangeNotifierProxyProvider<SessionViewModel, ProfileViewModel>(
          create: (context) =>
              ProfileViewModel(context.read<SessionViewModel>()),
          update: (_, session, previous) =>
              previous ?? ProfileViewModel(session),
        ),

        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProxyProvider<SessionViewModel, BrowseViewModel>(
          create: (_) {
            final memoryCache = LruCacheService<String, dynamic>();
            final localStorage = Hive.box<dynamic>('browse_view_model');
            return BrowseViewModel(memoryCache, localStorage);
          },
          update: (context, session, browse) {
            final memoryCache = LruCacheService<String, dynamic>();
            final localStorage = Hive.box<dynamic>('browse_view_model');
            browse ??= BrowseViewModel(memoryCache, localStorage);
            browse.reloadFavoritesForCurrentUser();
            return browse;
          },
        ),
        ChangeNotifierProxyProvider<SessionViewModel, SellerPerformanceViewModel>(
          create: (context) => SellerPerformanceViewModel(context.read<SessionViewModel>()),
          update: (_, session, previous) {
            if (previous == null) return SellerPerformanceViewModel(session);
            previous.updateSession(session);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<SessionViewModel, SellViewModel>(
          create: (context) => SellViewModel(context.read<SessionViewModel>()),
          update: (_, session, previous) {
            if (previous == null) return SellViewModel(session);
            previous.updateSession(session);
            return previous;
          },
        ),

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
