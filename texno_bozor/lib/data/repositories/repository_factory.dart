import '../database/app_database.dart';
import '../remote/api_client.dart';
import '../remote/backend_config.dart';
import 'api/api_cart_repository.dart';
import 'api/api_category_repository.dart';
import 'api/api_order_repository.dart';
import 'api/api_product_repository.dart';
import 'api/api_user_repository.dart';
import 'cart_repository.dart';
import 'category_repository.dart';
import 'favorites_repository.dart';
import 'history_repository.dart';
import 'order_repository.dart';
import 'pc_build_repository.dart';
import 'product_repository.dart';
import 'review_repository.dart';
import 'user_repository.dart';

/// Repository fabrikasi — implementatsiyani bitta joyda tanlaydi.
///
/// `BackendMode.local`  -> Drift (SQLite, offline).
/// `BackendMode.remote` -> REST API (+ lokal kesh).
///
/// Ekranlar faqat abstrakt interfeyslar bilan ishlagani uchun rejimni
/// almashtirish qolgan kodga umuman ta'sir qilmaydi.
class RepositoryFactory {
  RepositoryFactory({required this.db, required this.config})
      : api = config.isRemote ? ApiClient(config) : null;

  final AppDatabase db;
  final BackendConfig config;
  final ApiClient? api;

  bool get isRemote => api != null;

  ProductRepository products() {
    final client = api;
    return client == null
        ? DriftProductRepository(db)
        : ApiProductRepository(client, db);
  }

  CategoryRepository categories() {
    final client = api;
    return client == null
        ? DriftCategoryRepository(db)
        : ApiCategoryRepository(client, db);
  }

  CartRepository cart() {
    final client = api;
    return client == null
        ? DriftCartRepository(db)
        : ApiCartRepository(client, db);
  }

  OrderRepository orders(CartRepository cartRepository) {
    final client = api;
    return client == null
        ? DriftOrderRepository(db, cartRepository)
        : ApiOrderRepository(client, db, cartRepository);
  }

  UserRepository users() {
    final client = api;
    return client == null
        ? DriftUserRepository(db)
        : ApiUserRepository(client, db);
  }

  // Quyidagilar faqat qurilma ichida ma'noga ega (sevimlilar, tarix,
  // sharhlar keshi, PC yig'ilmalar) — hozircha lokal implementatsiya.
  FavoritesRepository favorites() => DriftFavoritesRepository(db);
  ReviewRepository reviews() => DriftReviewRepository(db);
  HistoryRepository history() => DriftHistoryRepository(db);
  PcBuildRepository pcBuilds() => DriftPcBuildRepository(db);
}
