import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/models/models.dart';
import '../data/remote/api_client.dart';
import '../data/repositories/repositories.dart';
import '../data/repositories/repository_factory.dart';
import '../data/services/ai_service.dart';

/// ILOVA HOLATI (Riverpod).
///
/// Ekranlar faqat shu provayderlar orqali ma'lumot oladi. Provayderlar esa
/// repository interfeyslariga tayanadi — shuning uchun ma'lumot manbasini
/// almashtirish (SQLite ↔ REST API) UI kodiga ta'sir qilmaydi.

/// Baza — `main()` da ochilib override qilinadi.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('AppDatabase override qilinishi kerak'),
);

/// Server sozlamalari. Bo'sh baseUrl = to'liq offline rejim.
final apiConfigProvider = StateProvider<ApiConfig>((ref) => const ApiConfig());

/// Repository fabrikasi — implementatsiya tanlanadigan yagona nuqta.
final repositoriesProvider = Provider<RepositoryFactory>((ref) {
  final factory = RepositoryFactory(
    db: ref.watch(databaseProvider),
    config: ref.watch(apiConfigProvider),
  );
  ref.onDispose(factory.dispose);
  return factory;
});

final productRepositoryProvider = Provider<ProductRepository>(
    (ref) => ref.watch(repositoriesProvider).products);
final categoryRepositoryProvider = Provider<CategoryRepository>(
    (ref) => ref.watch(repositoriesProvider).categories);
final cartRepositoryProvider =
    Provider<CartRepository>((ref) => ref.watch(repositoriesProvider).cart);
final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => ref.watch(repositoriesProvider).orders);
final userRepositoryProvider =
    Provider<UserRepository>((ref) => ref.watch(repositoriesProvider).users);
final favoritesRepositoryProvider = Provider<FavoritesRepository>(
    (ref) => ref.watch(repositoriesProvider).favorites);
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ref.watch(repositoriesProvider).reviews);
final historyRepositoryProvider = Provider<HistoryRepository>(
    (ref) => ref.watch(repositoriesProvider).history);
final pcBuildRepositoryProvider = Provider<PcBuildRepository>(
    (ref) => ref.watch(repositoriesProvider).pcBuilds);
final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ref.watch(repositoriesProvider).chat);

// ---------------------------------------------------------------------------
// Katalog
// ---------------------------------------------------------------------------

final categoriesProvider = FutureProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).getAll());

final categoryCountsProvider = FutureProvider<Map<String, int>>(
    (ref) => ref.watch(categoryRepositoryProvider).productCounts());

final allProductsProvider = FutureProvider<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).getAll());

final popularProductsProvider = FutureProvider<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).popular(limit: 10));

final newProductsProvider = FutureProvider<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).newest(limit: 10));

final discountedProductsProvider = FutureProvider<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).discounted(limit: 10));

final productByIdProvider =
    FutureProvider.family<Product?, String>((ref, id) async {
  // Sevimlilar/savat o'zgarganda mahsulot ma'lumoti ham yangilansin.
  ref.watch(cartProvider);
  return ref.watch(productRepositoryProvider).getById(id);
});

final similarProductsProvider =
    FutureProvider.family<List<Product>, Product>((ref, product) =>
        ref.watch(productRepositoryProvider).similar(product, limit: 8));

final productReviewsProvider = FutureProvider.family<List<Review>, String>(
    (ref, productId) =>
        ref.watch(reviewRepositoryProvider).forProduct(productId));

final brandsProvider = FutureProvider.family<List<String>, String?>(
    (ref, categoryId) =>
        ref.watch(productRepositoryProvider).brands(categoryId: categoryId));

final priceRangeProvider =
    FutureProvider.family<(int, int), String?>((ref, categoryId) =>
        ref.watch(productRepositoryProvider).priceRange(categoryId: categoryId));

/// Katalog ekrani filtri.
final catalogFilterProvider =
    StateProvider<ProductFilter>((ref) => const ProductFilter());

final filteredProductsProvider = FutureProvider<List<Product>>((ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref.watch(productRepositoryProvider).query(filter);
});

// ---------------------------------------------------------------------------
// Qidiruv
// ---------------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return Future.value(const []);
  return ref.watch(productRepositoryProvider).search(query);
});

final recentSearchesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(historyRepositoryProvider).recentSearches());

final recentlyViewedProvider = FutureProvider<List<Product>>((ref) async {
  final ids = await ref.watch(historyRepositoryProvider).recentlyViewed();
  if (ids.isEmpty) return const [];
  return ref.watch(productRepositoryProvider).getByIds(ids);
});

// ---------------------------------------------------------------------------
// Savat
// ---------------------------------------------------------------------------

/// Savat holati — barcha o'zgarishlar shu notifier orqali o'tadi.
class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final CartRepository _repository;

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.getCart);
  }

  Future<void> add(String productId, {int quantity = 1}) async {
    await _repository.add(productId, quantity: quantity);
    await refresh();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    await _repository.setQuantity(productId, quantity);
    await refresh();
  }

  Future<void> increment(String productId) async {
    final cart = state.value;
    final current = cart?.quantityOf(productId) ?? 0;
    await setQuantity(productId, current + 1);
  }

  Future<void> decrement(String productId) async {
    final cart = state.value;
    final current = cart?.quantityOf(productId) ?? 0;
    await setQuantity(productId, current - 1);
  }

  Future<void> remove(String productId) async {
    await _repository.remove(productId);
    await refresh();
  }

  Future<void> clear() async {
    await _repository.clear();
    await refresh();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<Cart>>((ref) {
  return CartNotifier(ref.watch(cartRepositoryProvider));
});

/// Pastki menyudagi savat belgisi uchun mahsulotlar soni.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).value?.count ?? 0;
});

/// Checkout ekranidagi yetkazish turi.
final deliveryTypeProvider =
    StateProvider<DeliveryType>((ref) => DeliveryType.courier);

/// Checkout ekranidagi to'lov usuli.
final paymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.cash);

// ---------------------------------------------------------------------------
// Sevimlilar
// ---------------------------------------------------------------------------

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  FavoritesNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final FavoritesRepository _repository;

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.ids);
  }

  /// Qaytaradi: qo'shildimi (true) yoki olib tashlandimi (false).
  Future<bool> toggle(String productId) async {
    final added = await _repository.toggle(productId);
    await refresh();
    return added;
  }

  bool contains(String productId) =>
      state.value?.contains(productId) ?? false;

  Future<void> clear() async {
    await _repository.clear();
    await refresh();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider));
});

final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(favoritesProvider).value ?? const <String>[];
  if (ids.isEmpty) return const [];
  return ref.watch(productRepositoryProvider).getByIds(ids);
});

// ---------------------------------------------------------------------------
// Buyurtmalar
// ---------------------------------------------------------------------------

class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  OrdersNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final OrderRepository _repository;

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.getAll);
  }

  Future<Order> create({
    required Cart cart,
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    required String customerName,
    required String phone,
    required String address,
    String comment = '',
  }) async {
    final order = await _repository.createFromCart(
      cart: cart,
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      customerName: customerName,
      phone: phone,
      address: address,
      comment: comment,
    );
    await refresh();
    return order;
  }

  Future<void> cancel(String orderId) async {
    await _repository.cancel(orderId);
    await refresh();
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  return OrdersNotifier(ref.watch(orderRepositoryProvider));
});

final orderByIdProvider = FutureProvider.family<Order?, String>((ref, id) {
  ref.watch(ordersProvider);
  return ref.watch(orderRepositoryProvider).getById(id);
});

/// Faol (yakunlanmagan) buyurtmalar soni — profil belgisi uchun.
final activeOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(ordersProvider).value ?? const <Order>[];
  return orders.where((o) => !o.status.isFinal).length;
});

// ---------------------------------------------------------------------------
// Profil
// ---------------------------------------------------------------------------

class UserNotifier extends StateNotifier<AsyncValue<AppUser>> {
  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  final UserRepository _repository;

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repository.getCurrent);
  }

  Future<void> save(AppUser user) async {
    await _repository.save(user);
    await refresh();
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<AppUser>>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});

// ---------------------------------------------------------------------------
// TEXNO AI
// ---------------------------------------------------------------------------

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.close);
  return service;
});

/// AI sozlamalari (API kalit) — Sozlamalar ekranidan kiritiladi.
final aiConfigProvider = StateProvider<AiConfig>((ref) => const AiConfig());

/// Suhbat holati.
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier(this._ref, this._repository)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final ChatRepository _repository;

  bool _thinking = false;

  bool get isThinking => _thinking;

  Future<void> load() async {
    state = await AsyncValue.guard(_repository.history);
  }

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _thinking) return;

    _thinking = true;
    await _repository.add(ChatMessage(
      id: 0,
      role: 'user',
      text: question,
      createdAt: DateTime.now(),
    ));
    await load();

    final catalog = await _ref.read(productRepositoryProvider).getAll();
    final history = state.value ?? const <ChatMessage>[];
    final reply = await _ref.read(aiServiceProvider).ask(
          question: question,
          catalog: catalog,
          history: history,
          config: _ref.read(aiConfigProvider),
        );

    await _repository.add(ChatMessage(
      id: 0,
      role: 'ai',
      text: reply.text,
      createdAt: DateTime.now(),
      productIds: reply.productIds,
    ));
    _thinking = false;
    await load();
  }

  Future<void> clear() async {
    await _repository.clear();
    await load();
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatNotifier(ref, ref.watch(chatRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Kompyuter yig'ish
// ---------------------------------------------------------------------------

final savedBuildsProvider = FutureProvider<List<PcBuild>>(
    (ref) => ref.watch(pcBuildRepositoryProvider).getAll());
