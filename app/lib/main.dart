import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'core/app_router.dart';
import 'core/auth_service.dart';
import 'core/theme/theme_context.dart';
import 'view_models/browse_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'view_models/sell_view_model.dart';
import 'view_models/session_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const UniMarketApp());
}

class UniMarketApp extends StatelessWidget {
  const UniMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeContext()),

        Provider(create: (_) => AuthService()),

        ChangeNotifierProvider(
          create: (context) => SessionViewModel(
            authService: context.read<AuthService>(),
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