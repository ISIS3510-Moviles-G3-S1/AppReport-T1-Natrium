import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/browse_screen.dart';
import '../views/screens/item_detail_screen.dart';
import '../views/screens/sell_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/not_found_screen.dart';
import '../views/screens/swap_screen.dart';
import '../views/screens/donate_screen.dart';
import '../views/widgets/main_shell.dart';
import '../view_models/item_detail_view_model.dart';
import 'package:provider/provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    errorBuilder: (_, __) => const NotFoundScreen(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/browse',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrowseScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/sell',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SellScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ChangeNotifierProvider(
            create: (_) => ItemDetailViewModel()..loadItem(id),
            child: const ItemDetailScreen(),
          );
        },
      ),
      GoRoute(
        path: '/swap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SwapScreen(),
      ),
      GoRoute(
        path: '/donate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DonateScreen(),
      ),
    ],
  );
}
