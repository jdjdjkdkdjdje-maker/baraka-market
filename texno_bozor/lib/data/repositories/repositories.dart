import '../models/models.dart';

/// ILOVANING SHARTNOMALARI (Repository pattern).
///
/// Ekranlar faqat shu abstrakt klasslarni biladi. Ma'lumot qayerdan kelishi —
/// telefondagi SQLite bazasidanmi yoki REST API + PostgreSQL serveridanmi —
/// ularga umuman ta'sir qilmaydi. Implementatsiyani almashtirish uchun
/// `RepositoryFactory` ichidagi bitta qatorni o'zgartirish yetarli.

/// Mahsulotlar ombori.
abstract class ProductRepository {
  Future<List<Product>> getAll();

  Future<Product?> getById(String id);

  Future<List<Product>> getByIds(List<String> ids);

  Future<List<Product>> getByCategory(String categoryId);

  /// Filtr + saralash bilan ro'yxat.
  Future<List<Product>> query(ProductFilter filter);

  /// Matn bo'yicha qidiruv (nom, brend, kategoriya, xususiyatlar).
  Future<List<Product>> search(String text);

  /// Bosh sahifa uchun: ommabop mahsulotlar.
  Future<List<Product>> popular({int limit = 10});

  /// Bosh sahifa uchun: yangi kelganlar.
  Future<List<Product>> newest({int limit = 10});

  /// Bosh sahifa uchun: chegirmadagilar.
  Future<List<Product>> discounted({int limit = 10});

  /// O'xshash mahsulotlar (bir kategoriya, narxi yaqin).
  Future<List<Product>> similar(Product product, {int limit = 8});

  Future<List<String>> brands({String? categoryId});

  /// Kategoriyadagi eng arzon va eng qimmat narx.
  Future<(int min, int max)> priceRange({String? categoryId});

  /// Buyurtma berilganda omborni kamaytirish.
  Future<void> decreaseStock(String productId, int quantity);
}

/// Kategoriyalar ombori.
abstract class CategoryRepository {
  Future<List<Category>> getAll();

  Future<Category?> getById(String id);

  /// Har bir kategoriyadagi mahsulotlar soni: {categoryId: count}.
  Future<Map<String, int>> productCounts();
}

/// Savat ombori.
abstract class CartRepository {
  Future<Cart> getCart();

  Future<void> add(String productId, {int quantity = 1});

  Future<void> setQuantity(String productId, int quantity);

  Future<void> remove(String productId);

  Future<void> clear();
}

/// Buyurtmalar ombori.
abstract class OrderRepository {
  Future<List<Order>> getAll();

  Future<Order?> getById(String id);

  /// Savatdan buyurtma yaratadi: ombordan mahsulot ayiriladi va savat tozalanadi.
  Future<Order> createFromCart({
    required Cart cart,
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    required String customerName,
    required String phone,
    required String address,
    String comment = '',
  });

  Future<void> updateStatus(String orderId, OrderStatus status);

  Future<void> cancel(String orderId);
}

/// Foydalanuvchi ombori.
abstract class UserRepository {
  Future<AppUser> getCurrent();

  Future<void> save(AppUser user);

  /// Sozlama o'qish/yozish (tema, til va h.k.).
  Future<String?> getSetting(String key);

  Future<void> setSetting(String key, String value);
}

/// Sevimlilar ombori.
abstract class FavoritesRepository {
  Future<List<String>> ids();

  Future<bool> contains(String productId);

  /// Qaytaradi: sevimlilarga qo'shildimi (true) yoki olib tashlandimi (false).
  Future<bool> toggle(String productId);

  Future<void> clear();
}

/// Sharhlar ombori.
abstract class ReviewRepository {
  Future<List<Review>> forProduct(String productId);

  Future<void> add(Review review);
}

/// Qidiruv tarixi va ko'rilgan mahsulotlar.
abstract class HistoryRepository {
  Future<List<String>> recentSearches({int limit = 10});

  Future<void> addSearch(String query);

  Future<void> clearSearches();

  Future<List<String>> recentlyViewed({int limit = 10});

  Future<void> addViewed(String productId);
}

/// Kompyuter yig'ilmalari ombori.
abstract class PcBuildRepository {
  Future<List<PcBuild>> getAll();

  Future<void> save(PcBuild build);

  Future<void> delete(String id);
}

/// TEXNO AI suhbat tarixi.
abstract class ChatRepository {
  Future<List<ChatMessage>> history({int limit = 100});

  Future<ChatMessage> add(ChatMessage message);

  Future<void> clear();
}
