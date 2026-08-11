import '../../models/models.dart';
import '../../remote/api_client.dart';
import '../repositories.dart';

/// REST API + PostgreSQL implementatsiyalari.
///
/// Bu fayl repository patternning asosiy foydasini ko'rsatadi: server tayyor
/// bo'lganda `RepositoryFactory` shu klasslarni qaytaradi va ekranlarning
/// birorta qatori ham o'zgarmaydi.
///
/// Offline-first tamoyili saqlanadi: server javob bermasa yoki internet
/// bo'lmasa, so'rov avtomatik lokal SQLite implementatsiyasiga (`fallback`)
/// tushadi.

/// Serverdan kelgan JSON'ni domen modeliga aylantirish.
class ApiMappers {
  const ApiMappers._();

  static Product product(Map<String, Object?> json) => Product(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        brand: '${json['brand'] ?? ''}',
        categoryId: '${json['categoryId'] ?? json['category_id'] ?? ''}',
        price: _int(json['price']),
        oldPrice: _int(json['oldPrice'] ?? json['old_price']),
        rating: _double(json['rating']),
        ratingCount: _int(json['ratingCount'] ?? json['rating_count']),
        stock: _int(json['stock']),
        description: '${json['description'] ?? ''}',
        specs: _specs(json['specs']),
        image: '${json['image'] ?? ''}',
        popularity: _int(json['popularity']),
        createdAt: _date(json['createdAt'] ?? json['created_at']),
      );

  static Category category(Map<String, Object?> json) => Category(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        image: '${json['image'] ?? ''}',
        group: '${json['group'] ?? json['grp'] ?? ''}',
        sort: _int(json['sort']),
      );

  static AppUser user(Map<String, Object?> json) => AppUser(
        id: '${json['id'] ?? AppUser.localId}',
        name: '${json['name'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        email: '${json['email'] ?? ''}',
        address: '${json['address'] ?? ''}',
        city: '${json['city'] ?? 'Toshkent'}',
      );

  static OrderItem orderItem(Map<String, Object?> json) => OrderItem(
        productId: '${json['productId'] ?? json['product_id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        price: _int(json['price']),
        quantity: _int(json['quantity'], fallback: 1),
        image: '${json['image'] ?? ''}',
      );

  static Order order(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => orderItem(e.cast<String, Object?>()))
            .toList()
        : <OrderItem>[];
    return Order(
      id: '${json['id']}',
      createdAt: _date(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
      status: OrderStatus.fromName('${json['status']}'),
      items: items,
      subtotal: _int(json['subtotal']),
      deliveryFee: _int(json['deliveryFee'] ?? json['delivery_fee']),
      deliveryType:
          DeliveryType.fromName('${json['deliveryType'] ?? json['delivery_type']}'),
      paymentMethod: PaymentMethod.fromName(
          '${json['paymentMethod'] ?? json['payment_method']}'),
      customerName: '${json['customerName'] ?? json['customer_name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      comment: '${json['comment'] ?? ''}',
    );
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _date(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Map<String, String> _specs(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', '$v'));
    }
    return const {};
  }
}

/// Mahsulotlar ombori — REST API implementatsiyasi.
///
/// Kutilayotgan endpointlar:
///   GET /products?category=&search=&sort=
///   GET /products/:id
///   GET /products/brands
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this.api, this.fallback);

  final ApiClient api;

  /// Internet bo'lmaganda ishlatiladigan lokal ombor.
  final ProductRepository fallback;

  Future<T> _guard<T>(
    Future<T> Function() remote,
    Future<T> Function() local,
  ) async {
    try {
      return await remote();
    } on ApiException {
      return local();
    }
  }

  List<Product> _parse(dynamic data) =>
      ApiClient.listOf(data).map(ApiMappers.product).toList();

  @override
  Future<List<Product>> getAll() =>
      _guard(() async => _parse(await api.get('/products')), fallback.getAll);

  @override
  Future<Product?> getById(String id) => _guard(() async {
        final json = ApiClient.objectOf(await api.get('/products/$id'));
        if (json == null) return fallback.getById(id);
        return ApiMappers.product(json);
      }, () => fallback.getById(id));

  @override
  Future<List<Product>> getByIds(List<String> ids) => _guard(
        () async => _parse(
            await api.get('/products', query: {'ids': ids.join(',')})),
        () => fallback.getByIds(ids),
      );

  @override
  Future<List<Product>> getByCategory(String categoryId) => _guard(
        () async =>
            _parse(await api.get('/products', query: {'category': categoryId})),
        () => fallback.getByCategory(categoryId),
      );

  @override
  Future<List<Product>> query(ProductFilter filter) => _guard(
        () async => _parse(await api.get('/products', query: {
          'category': filter.categoryId,
          'search': filter.query.isEmpty ? null : filter.query,
          'brands': filter.brands.isEmpty ? null : filter.brands.join(','),
          'minPrice': filter.minPrice,
          'maxPrice': filter.maxPrice,
          'minRating': filter.minRating > 0 ? filter.minRating : null,
          'inStock': filter.onlyInStock ? 'true' : null,
          'discount': filter.onlyDiscount ? 'true' : null,
          'sort': filter.sort.name,
        })),
        () => fallback.query(filter),
      );

  @override
  Future<List<Product>> search(String text) => _guard(
        () async => _parse(await api.get('/products', query: {'search': text})),
        () => fallback.search(text),
      );

  @override
  Future<List<Product>> popular({int limit = 10}) => _guard(
        () async => _parse(await api
            .get('/products', query: {'sort': 'popular', 'limit': limit})),
        () => fallback.popular(limit: limit),
      );

  @override
  Future<List<Product>> newest({int limit = 10}) => _guard(
        () async => _parse(await api
            .get('/products', query: {'sort': 'newest', 'limit': limit})),
        () => fallback.newest(limit: limit),
      );

  @override
  Future<List<Product>> discounted({int limit = 10}) => _guard(
        () async => _parse(await api
            .get('/products', query: {'discount': 'true', 'limit': limit})),
        () => fallback.discounted(limit: limit),
      );

  @override
  Future<List<Product>> similar(Product product, {int limit = 8}) => _guard(
        () async => _parse(await api
            .get('/products/${product.id}/similar', query: {'limit': limit})),
        () => fallback.similar(product, limit: limit),
      );

  @override
  Future<List<String>> brands({String? categoryId}) => _guard(() async {
        final data =
            await api.get('/products/brands', query: {'category': categoryId});
        final raw = data is Map ? data['data'] : data;
        if (raw is List) return raw.map((e) => '$e').toList();
        return fallback.brands(categoryId: categoryId);
      }, () => fallback.brands(categoryId: categoryId));

  @override
  Future<(int, int)> priceRange({String? categoryId}) => _guard(() async {
        final json = ApiClient.objectOf(
            await api.get('/products/price-range', query: {'category': categoryId}));
        if (json == null) return fallback.priceRange(categoryId: categoryId);
        return (ApiMappers._int(json['min']), ApiMappers._int(json['max']));
      }, () => fallback.priceRange(categoryId: categoryId));

  @override
  Future<void> decreaseStock(String productId, int quantity) => _guard(
        () async => await api.patch('/products/$productId/stock',
            body: {'decrease': quantity}),
        () => fallback.decreaseStock(productId, quantity),
      );
}

/// Kategoriyalar ombori — REST API implementatsiyasi.
class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this.api, this.fallback);

  final ApiClient api;
  final CategoryRepository fallback;

  @override
  Future<List<Category>> getAll() async {
    try {
      return ApiClient.listOf(await api.get('/categories'))
          .map(ApiMappers.category)
          .toList();
    } on ApiException {
      return fallback.getAll();
    }
  }

  @override
  Future<Category?> getById(String id) async {
    try {
      final json = ApiClient.objectOf(await api.get('/categories/$id'));
      if (json == null) return fallback.getById(id);
      return ApiMappers.category(json);
    } on ApiException {
      return fallback.getById(id);
    }
  }

  @override
  Future<Map<String, int>> productCounts() async {
    try {
      final json = ApiClient.objectOf(await api.get('/categories/counts'));
      if (json == null) return fallback.productCounts();
      return json.map((k, v) => MapEntry(k, ApiMappers._int(v)));
    } on ApiException {
      return fallback.productCounts();
    }
  }
}

/// Savat ombori — REST API implementatsiyasi.
class ApiCartRepository implements CartRepository {
  ApiCartRepository(this.api, this.fallback, this.products);

  final ApiClient api;
  final CartRepository fallback;
  final ProductRepository products;

  @override
  Future<Cart> getCart() async {
    try {
      final rows = ApiClient.listOf(await api.get('/cart'));
      final lines = <CartLine>[];
      for (final row in rows) {
        final id = '${row['productId'] ?? row['product_id'] ?? ''}';
        final qty = ApiMappers._int(row['quantity'], fallback: 1);
        final product = row['product'] is Map
            ? ApiMappers.product((row['product'] as Map).cast<String, Object?>())
            : await products.getById(id);
        if (product == null) continue;
        lines.add(CartLine(product: product, quantity: qty));
      }
      return Cart(lines);
    } on ApiException {
      return fallback.getCart();
    }
  }

  @override
  Future<void> add(String productId, {int quantity = 1}) async {
    // Savat har doim lokal ham yangilanadi — offline rejimda yo'qolmasin.
    await fallback.add(productId, quantity: quantity);
    try {
      await api
          .post('/cart', body: {'productId': productId, 'quantity': quantity});
    } on ApiException {
      // Internet yo'q — lokal savat yetarli, keyin sinxronlanadi.
    }
  }

  @override
  Future<void> setQuantity(String productId, int quantity) async {
    await fallback.setQuantity(productId, quantity);
    try {
      await api.put('/cart/$productId', body: {'quantity': quantity});
    } on ApiException {
      // offline
    }
  }

  @override
  Future<void> remove(String productId) async {
    await fallback.remove(productId);
    try {
      await api.delete('/cart/$productId');
    } on ApiException {
      // offline
    }
  }

  @override
  Future<void> clear() async {
    await fallback.clear();
    try {
      await api.delete('/cart');
    } on ApiException {
      // offline
    }
  }
}

/// Buyurtmalar ombori — REST API implementatsiyasi.
class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this.api, this.fallback);

  final ApiClient api;
  final OrderRepository fallback;

  @override
  Future<List<Order>> getAll() async {
    try {
      return ApiClient.listOf(await api.get('/orders'))
          .map(ApiMappers.order)
          .toList();
    } on ApiException {
      return fallback.getAll();
    }
  }

  @override
  Future<Order?> getById(String id) async {
    try {
      final json = ApiClient.objectOf(await api.get('/orders/$id'));
      if (json == null) return fallback.getById(id);
      return ApiMappers.order(json);
    } on ApiException {
      return fallback.getById(id);
    }
  }

  @override
  Future<Order> createFromCart({
    required Cart cart,
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    required String customerName,
    required String phone,
    required String address,
    String comment = '',
  }) async {
    // Buyurtma avval lokal yaratiladi — internet uzilsa ham yo'qolmaydi.
    final local = await fallback.createFromCart(
      cart: cart,
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      customerName: customerName,
      phone: phone,
      address: address,
      comment: comment,
    );
    try {
      final json = ApiClient.objectOf(await api.post('/orders', body: {
        'items': [
          for (final item in local.items)
            {'productId': item.productId, 'quantity': item.quantity},
        ],
        'deliveryType': deliveryType.name,
        'paymentMethod': paymentMethod.name,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'comment': comment,
      }));
      if (json != null) return ApiMappers.order(json);
    } on ApiException {
      // offline — lokal buyurtma qaytadi
    }
    return local;
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await fallback.updateStatus(orderId, status);
    try {
      await api.patch('/orders/$orderId', body: {'status': status.name});
    } on ApiException {
      // offline
    }
  }

  @override
  Future<void> cancel(String orderId) async {
    await fallback.cancel(orderId);
    try {
      await api.post('/orders/$orderId/cancel');
    } on ApiException {
      // offline
    }
  }
}

/// Foydalanuvchi ombori — REST API implementatsiyasi.
class ApiUserRepository implements UserRepository {
  ApiUserRepository(this.api, this.fallback);

  final ApiClient api;
  final UserRepository fallback;

  @override
  Future<AppUser> getCurrent() async {
    try {
      final json = ApiClient.objectOf(await api.get('/users/me'));
      if (json == null) return fallback.getCurrent();
      final user = ApiMappers.user(json);
      await fallback.save(user); // keshlash
      return user;
    } on ApiException {
      return fallback.getCurrent();
    }
  }

  @override
  Future<void> save(AppUser user) async {
    await fallback.save(user);
    try {
      await api.put('/users/me', body: user.toMap());
    } on ApiException {
      // offline
    }
  }

  @override
  Future<String?> getSetting(String key) => fallback.getSetting(key);

  @override
  Future<void> setSetting(String key, String value) =>
      fallback.setSetting(key, value);
}
