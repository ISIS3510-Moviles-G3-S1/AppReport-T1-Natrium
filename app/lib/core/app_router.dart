import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Screens
import '../views/screens/home_screen.dart';
import '../views/screens/browse_screen.dart';
import '../views/screens/item_detail_screen.dart';
import '../views/screens/sell_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/activity_listings_screen.dart';
import '../views/screens/not_found_screen.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/register_screen.dart';
import '../views/screens/meetup_generate_qr_screen.dart';
import '../views/screens/meetup_scan_qr_screen.dart';
import '../views/screens/chat_screen.dart';
import '../views/screens/inbox_screen.dart';

// Widgets
import 'package:uni_market/views/widgets/main_shell.dart';

// ViewModels
import 'package:uni_market/view_models/item_detail_view_model.dart';
import 'package:uni_market/view_models/session_view_model.dart';
import 'package:uni_market/view_models/chat_view_model.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(SessionViewModel session) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',

    redirect: (context, state) {
      final location =
          state.matchedLocation.isEmpty
              ? state.uri.path
              : state.matchedLocation;

      final isLoading = session.isLoading;
      final isAuth = session.isAuthenticated;

      final onLoading = location == '/loading';
      final onLogin = location == '/login';
      final onRegister = location == '/register';

      /// 🔥 FIX CLAVE
      final onAuthRoute = onLogin || onRegister;

      /// LOADING
      if (isLoading) {
        return onLoading ? null : '/loading';
      }

      /// NOT AUTHENTICATED
      if (!isAuth) {
        return onAuthRoute ? null : '/login';
      }

      /// AUTHENTICATED
      if (onLogin || onRegister || onLoading) {
        return '/';
      }

      return null;
    },

    errorBuilder: (_, __) => const NotFoundScreen(),

    routes: [
      /// LOADING
      GoRoute(
        path: '/loading',
        builder:
            (_, __) => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
      ),

      /// LOGIN
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      /// REGISTER ✅ (YA PERMITIDO)
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      /// CHAT
      GoRoute(
        path: '/chat/:conversationId/:otherUserId/:otherUserName/:itemName',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final otherUserId = state.pathParameters['otherUserId']!;
          final otherUserName = state.pathParameters['otherUserName']!;
          final itemName = Uri.decodeComponent(state.pathParameters['itemName']!);
          return ChangeNotifierProvider(
            create: (_) => ChatViewModel(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              itemName: itemName,
            ),
            child: ChatScreen(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              itemName: itemName,
            ),
          );
        },
      ),

      /// INBOX
      GoRoute(
        path: '/inbox',
        builder: (_, __) => const InboxScreen(),
      ),

      /// ITEM DETAIL
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => ItemDetailViewModel()..loadItem(id),
            child: const ItemDetailScreen(),
          );
        },
      ),

      /// MAIN APP
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: BrowseScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sell',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: SellScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity-listings',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: ActivityListingsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder:
                    (context, state) =>
                        const NoTransitionPage(child: ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // Removed swap and donate routes

      // Rutas swap y donate eliminadas
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id'] ?? '';
          return ChangeNotifierProvider(
            create: (_) => ItemDetailViewModel()..loadItem(listingId),
            child: const ItemDetailScreen(),
          );
        },
      ),
      GoRoute(
        path: '/meetup/seller/:listingId',
        builder: (context, state) {
          final listingId = state.pathParameters['listingId'] ?? '';
          final sellerId = state.uri.queryParameters['sellerId'] ?? '';
          return MeetupGenerateQrScreen(
            listingId: listingId,
            sellerId: sellerId,
          );
        },
      ),
      GoRoute(
        path: '/meetup/scan',
        builder: (_, __) => const MeetupScanQrScreen(),
      ),
    ],
  );
}
