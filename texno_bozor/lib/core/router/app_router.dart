import 'package:flutter/material.dart';

import '../../features/catalog/catalog_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/pc_builder/pc_builder_screen.dart';
import '../../features/product/product_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/texno_ai/ai_screen.dart';
import '../widgets/app_widgets.dart';
import 'app_shell.dart';

/// Ilova marshrutlari.
///
/// Asosiy 5 bo'lim pastki menyuda (AppShell), qolganlari alohida sahifa
/// sifatida ochiladi.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case '/':
        page = const AppShell();
      case '/catalog':
        page = const CatalogScreen();
      case '/search':
        page = const SearchScreen();
      case '/cart':
        page = const CartScreen();
      case '/checkout':
        page = const CheckoutScreen();
      case '/favorites':
        page = const FavoritesScreen();
      case '/orders':
        page = const OrdersScreen();
      case '/pc-builder':
        page = const PcBuilderScreen();
      case '/ai':
        page = const AiScreen();
      case '/settings':
        page = const SettingsScreen();
      case '/product':
        final id = settings.arguments;
        page = id is String
            ? ProductScreen(productId: id)
            : const _NotFound(message: 'Mahsulot identifikatori berilmagan');
      case '/order-detail':
        final id = settings.arguments;
        page = id is String
            ? OrderDetailScreen(orderId: id)
            : const _NotFound(message: 'Buyurtma identifikatori berilmagan');
      case '/order-success':
        final id = settings.arguments;
        page = id is String
            ? OrderSuccessScreen(orderId: id)
            : const _NotFound(message: 'Buyurtma topilmadi');
      default:
        page = _NotFound(message: 'Sahifa topilmadi: ${settings.name}');
    }

    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: 'Sahifa topilmadi',
        message: message,
        actionLabel: 'Bosh sahifaga qaytish',
        onAction: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    );
  }
}
