import '../local/app_database.dart';
import '../remote/api_client.dart';
import 'api/api_repositories.dart';
import 'local/local_cart_repository.dart';
import 'local/local_category_repository.dart';
import 'local/local_misc_repositories.dart';
import 'local/local_order_repository.dart';
import 'local/local_product_repository.dart';
import 'repositories.dart';

/// REPOSITORY FABRIKASI — implementatsiya tanlanadigan YAGONA joy.
///
/// Ilova sukut bo'yicha `ApiConfig(baseUrl: '')` bilan ishlaydi, ya'ni
/// hamma narsa telefon ichidagi SQLite'dan o'qiladi: server, VPS, PostgreSQL
/// kerak emas.
///
/// Kelajakda REST API + PostgreSQL tayyor bo'lsa — Profil > Sozlamalar'da
/// server manzili kiritiladi, fabrika `Api*Repository` larni qaytara
/// boshlaydi va ekranlarning birorta qatori ham o'zgarmaydi.
class RepositoryFactory {
  RepositoryFactory({required this.db, this.config = const ApiConfig()})
      : api = config.isEnabled ? ApiClient(config) : null {
    final localProducts = LocalProductRepository(db);
    final localCategories = LocalCategoryRepository(db);
    final localCart = LocalCartRepository(db, localProducts);
    final localOrders = LocalOrderRepository(db, localCart, localProducts);
    final localUsers = LocalUserRepository(db);

    final client = api;
    products = client == null
        ? localProducts
        : ApiProductRepository(client, localProducts);
    categories = client == null
        ? localCategories
        : ApiCategoryRepository(client, localCategories);
    cart = client == null
        ? localCart
        : ApiCartRepository(client, localCart, products);
    orders =
        client == null ? localOrders : ApiOrderRepository(client, localOrders);
    users = client == null ? localUsers : ApiUserRepository(client, localUsers);

    // Quyidagilar tabiatan qurilma ichidagi ma'lumot (sevimlilar, tarix,
    // yig'ilmalar, AI suhbati) — server rejimida ham lokal qoladi.
    favorites = LocalFavoritesRepository(db);
    reviews = LocalReviewRepository(db);
    history = LocalHistoryRepository(db);
    pcBuilds = LocalPcBuildRepository(db);
    chat = LocalChatRepository(db);
  }

  final AppDatabase db;
  final ApiConfig config;
  final ApiClient? api;

  /// Ilova hozir server rejimidami?
  bool get isRemote => api != null;

  late final ProductRepository products;
  late final CategoryRepository categories;
  late final CartRepository cart;
  late final OrderRepository orders;
  late final UserRepository users;
  late final FavoritesRepository favorites;
  late final ReviewRepository reviews;
  late final HistoryRepository history;
  late final PcBuildRepository pcBuilds;
  late final ChatRepository chat;

  void dispose() => api?.close();
}
