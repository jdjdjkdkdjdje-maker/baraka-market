import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/database/app_database.dart';
import '../data/models/app_models.dart';
import '../data/models/enums.dart';
import '../data/repositories/cart_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/history_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/pc_build_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/ai_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/payment_service.dart';
import 'utils/format.dart';

// ---------------------------------------------------------------- DATABASE

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ------------------------------------------------------------ REPOSITORIES

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductRepository(ref.watch(databaseProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(databaseProvider)),
);
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => DriftCartRepository(ref.watch(databaseProvider)),
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => DriftOrderRepository(
    ref.watch(databaseProvider),
    ref.watch(cartRepositoryProvider),
  ),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => DriftUserRepository(ref.watch(databaseProvider)),
);
final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => DriftFavoritesRepository(ref.watch(databaseProvider)),
);
final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => DriftReviewRepository(ref.watch(databaseProvider)),
);
final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => DriftHistoryRepository(ref.watch(databaseProvider)),
);
final pcBuildRepositoryProvider = Provider<PcBuildRepository>(
  (ref) => DriftPcBuildRepository(ref.watch(databaseProvider)),
);

// --------------------------------------------------------------- SERVICES

final authService = Provider<AuthService>(
  (ref) => LocalAuthService(ref.watch(userRepositoryProvider)),
);

final appStateProvider = ChangeNotifierProvider<AppStateNotifier>((ref) {
  final notifier = AppStateNotifier(
    ref.read(authService),
    ref.read(userRepositoryProvider),
  );
  notifier.init();
  return notifier;
});

final connectivityProvider = StreamProvider<bool>(
  (ref) => ConnectivityService().onConnectivityChanged,
);

final aiServiceProvider = Provider<AiService>(
  (ref) => AiService(const FlutterSecureStorage()),
);

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => LocalTestPaymentService(),
);

// ------------------------------------------------------------------ STREAMS

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

final cartItemsProvider = StreamProvider<List<CartEntry>>(
  (ref) => ref.watch(cartRepositoryProvider).watchItems(),
);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartItemsProvider).maybeWhen(
        data: (items) => items.length,
        orElse: () => 0,
      );
});

final cartSummaryProvider = Provider<Map<String, int>>((ref) {
  final items = ref.watch(cartItemsProvider).valueOrNull ?? [];
  var subtotal = 0;
  var discount = 0;
  for (final e in items) {
    subtotal += e.product.price * e.qty;
    discount += e.totalDiscount;
  }
  return {'subtotal': subtotal, 'discount': discount};
});

final favoritesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(favoritesRepositoryProvider).watchIds(),
);

final favoriteProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(favoritesRepositoryProvider).watchProducts(),
);

final ordersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).watchAll(),
);

final searchHistoryProvider = StreamProvider<List<SearchHistoryEntry>>(
  (ref) => ref.watch(historyRepositoryProvider).watchSearchHistory(),
);

final recentlyViewedProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(historyRepositoryProvider).watchRecentlyViewed(),
);

final pcBuildsProvider = StreamProvider<List<PcBuild>>(
  (ref) => ref.watch(pcBuildRepositoryProvider).watchAll(),
);

// ------------------------------------------------------------------ CATALOG

final catalogFilterProvider =
    StateProvider<ProductFilter>((ref) => const ProductFilter());

final filteredProductsProvider =
    Provider<AsyncValue<List<Product>>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref.watch(productsProvider).whenData((all) {
    var list = all.where((p) {
      if (filter.categoryId != null && p.categoryId != filter.categoryId) {
        return false;
      }
      if (filter.brands.isNotEmpty && !filter.brands.contains(p.brand)) {
        return false;
      }
      if (filter.minPrice != null && p.price < filter.minPrice!) return false;
      if (filter.maxPrice != null && p.price > filter.maxPrice!) return false;
      if (p.rating < filter.minRating) return false;
      return true;
    }).toList();

    switch (filter.sort) {
      case ProductSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ProductSort.discount:
        list.sort((a, b) {
          final da = discountPercent(a.price, a.oldPrice);
          final db2 = discountPercent(b.price, b.oldPrice);
          return db2.compareTo(da);
        });
      case ProductSort.popular:
        list.sort((a, b) => b.popularity.compareTo(a.popularity));
    }
    return list;
  });
});
