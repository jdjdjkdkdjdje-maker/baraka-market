import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/pc_builder/pc_builder_screen.dart';
import '../../features/product/product_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/texno_ai/ai_screen.dart';
import '../providers.dart';
import 'scaffold_with_nav.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final appState = ref.read(appStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: appState,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!appState.initialized) {
        return location == '/splash' ? null : '/splash';
      }
      if (appState.currentUser == null) {
        return location == '/login' ? null : '/login';
      }
      if (location == '/login' || location == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => CatalogScreen(
              initialCategoryId: state.uri.queryParameters['cat'],
              initialBrand: state.uri.queryParameters['brand'],
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success/:id',
        builder: (context, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pc-builder',
        builder: (context, state) => const PcBuilderScreen(),
      ),
      GoRoute(
        path: '/texno-ai',
        builder: (context, state) => const AiScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
