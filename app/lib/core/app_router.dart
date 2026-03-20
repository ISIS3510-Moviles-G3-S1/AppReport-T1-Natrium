import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Screens
import 'package:uni_market/views/screens/home_screen.dart';
import 'package:uni_market/views/screens/browse_screen.dart';
import 'package:uni_market/views/screens/item_detail_screen.dart';
import 'package:uni_market/views/screens/sell_screen.dart';
import 'package:uni_market/views/screens/profile_screen.dart';
import 'package:uni_market/views/screens/activity_listings_screen.dart';
import 'package:uni_market/views/screens/not_found_screen.dart';
import 'package:uni_market/views/screens/swap_screen.dart';
import 'package:uni_market/views/screens/donate_screen.dart';
import 'package:uni_market/views/screens/login_screen.dart';

// Widgets
import 'package:uni_market/views/widgets/main_shell.dart';

// ViewModels
import 'package:uni_market/view_models/item_detail_view_model.dart';
import 'package:uni_market/view_models/session_view_model.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(SessionViewModel session) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: session,
    redirect: (context, state) {
      final location =
          state.matchedLocation.isEmpty ? state.uri.path : state.matchedLocation;
      final isLoading = session.isLoading;
      final isAuth = session.isAuthenticated;
      final onLoading = location == '/loading';
      final onLogin = location == '/login';

      if (isLoading) {
        return onLoading ? null : '/loading';
      }

      if (!isAuth) {
        return onLogin ? null : '/login';
      }

      if (onLogin || onLoading) {
        return '/';
      }

      return null;
    },
    errorBuilder: (_, __) => const NotFoundScreen(),

    routes: [
      /// LOADING
      GoRoute(
        path: '/loading',
        builder: (_, __) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      /// MAIN APP (TABS)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrowseScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sell',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SellScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity-listings',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ActivityListingsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
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

      /// ITEM DETAIL
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

      /// SWAP
      GoRoute(
        path: '/swap',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SwapScreen(),
      ),

      /// DONATE
      GoRoute(
        path: '/donate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DonateScreen(),
      ),
    ],
  );
}
