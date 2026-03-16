import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_router.dart';
import 'core/theme/theme_context.dart';
import 'view_models/home_view_model.dart';
import 'view_models/browse_view_model.dart';
import 'view_models/sell_view_model.dart';
import 'view_models/profile_view_model.dart';

void main() {
  runApp(const UniMarketApp());
}

class UniMarketApp extends StatelessWidget {
  const UniMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // [Strategy Pattern] — ThemeContext is the "context" object.
        // It holds the currently active ThemeStrategy and notifies the
        // widget tree whenever the strategy — and therefore the theme — changes.
        // Registered first so other providers can read it if needed.
        ChangeNotifierProvider(create: (_) => ThemeContext()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => BrowseViewModel()),
        ChangeNotifierProvider(create: (_) => SellViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      // Consumer<ThemeContext> rebuilds only this subtree when the theme
      // changes, keeping all other providers and their subtrees unaffected.
      child: Consumer<ThemeContext>(
        builder: (context, themeCtx, _) => MaterialApp.router(
          title: 'UniMarket',
          // Delegate theme resolution entirely to the active strategy.
          // The context calls themeCtx.currentTheme → strategy.getTheme().
          theme: themeCtx.currentTheme,
          routerConfig: createAppRouter(),
        ),
      ),
    );
  }
}
