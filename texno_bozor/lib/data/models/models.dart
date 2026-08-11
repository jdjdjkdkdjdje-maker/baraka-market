import 'dart:convert';

/// Barcha domen modellari shu yerda — ilovaning "tili".
/// Modellar hech qanday bazaga yoki tarmoqqa bog'liq emas, shuning uchun
/// repository implementatsiyasini (SQLite ↔ REST API) almashtirsa ham
/// ekranlar o'zgarmaydi.

// ---------------------------------------------------------------------------
// Kategoriya
// ---------------------------------------------------------------------------

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.image,
    this.group = '',
    this.sort = 0,
  });

  final String id;
  final String name;

  /// Asset yo'li yoki URL.
  final String image;

  /// Guruh: "Kompyuter", "Mobil", "Aksessuar" va h.k.
  final String group;
  final int sort;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'image': image,
        'grp': group,
        'sort': sort,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        image: (map['image'] as String?) ?? '',
        group: (map['grp'] as String?) ?? '',
        sort: (map['sort'] as int?) ?? 0,
      );
}

// ---------------------------------------------------------------------------
// Mahsulot
// ---------------------------------------------------------------------------

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.price,
    this.oldPrice = 0,
    this.rating = 0,
    this.ratingCount = 0,
    this.stock = 0,
    this.description = '',
    this.specs = const {},
    this.image = '',
    this.popularity = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String brand;
  final String categoryId;

  /// Narx — so'mda (butun son).
  final int price;

  /// Chegirmagacha bo'lgan narx. 0 bo'lsa chegirma yo'q.
  final int oldPrice;
  final double rating;
  final int ratingCount;
  final int stock;
  final String description;

  /// Texnik xususiyatlar: {"socket": "AM5", "tdp": "105"} kabi.
  final Map<String, String> specs;
  final String image;
  final int popularity;
  final DateTime? createdAt;

  bool get inStock => stock > 0;

  bool get hasDiscount => oldPrice > price && price > 0;

  int get discountPercent =>
      hasDiscount ? (((oldPrice - price) / oldPrice) * 100).round() : 0;

  bool get isNew {
    final created = createdAt;
    if (created == null) return false;
    return DateTime.now().difference(created).inDays <= 30;
  }

  /// Xususiyatdan son ajratib olish: "105 W" -> 105.
  int specInt(String key, {int fallback = 0}) {
    final raw = specs[key];
    if (raw == null) return fallback;
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }

  String spec(String key) => specs[key] ?? '';

  Product copyWith({int? stock, int? price}) => Product(
        id: id,
        name: name,
        brand: brand,
        categoryId: categoryId,
        price: price ?? this.price,
        oldPrice: oldPrice,
        rating: rating,
        ratingCount: ratingCount,
        stock: stock ?? this.stock,
        description: description,
        specs: specs,
        image: image,
        popularity: popularity,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category_id': categoryId,
        'price': price,
        'old_price': oldPrice,
        'rating': rating,
        'rating_count': ratingCount,
        'stock': stock,
        'description': description,
        'specs': jsonEncode(specs),
        'image': image,
        'popularity': popularity,
        'created_at':
            (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      };

  factory Product.fromMap(Map<String, Object?> map) {
    final rawSpecs = map['specs'];
    Map<String, String> specs = const {};
    if (rawSpecs is String && rawSpecs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSpecs);
        if (decoded is Map) {
          specs = decoded.map((k, v) => MapEntry('$k', '$v'));
        }
      } catch (_) {
        specs = const {};
      }
    }
    return Product(
      id: '${map['id']}',
      name: '${map['name']}',
      brand: '${map['brand'] ?? ''}',
      categoryId: '${map['category_id'] ?? ''}',
      price: (map['price'] as num?)?.toInt() ?? 0,
      oldPrice: (map['old_price'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      description: '${map['description'] ?? ''}',
      specs: specs,
      image: '${map['image'] ?? ''}',
      popularity: (map['popularity'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['created_at'] as num).toInt()),
    );
  }
}

// ---------------------------------------------------------------------------
// Savat
// ---------------------------------------------------------------------------

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get total => product.price * quantity;
}

class Cart {
  const Cart(this.lines);

  final List<CartLine> lines;

  static const Cart empty = Cart([]);

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  int get count => lines.fold(0, (sum, l) => sum + l.quantity);

  int get subtotal => lines.fold(0, (sum, l) => sum + l.total);

  /// 5 mln so'mdan yuqori buyurtmada yetkazish bepul.
  int deliveryFee(DeliveryType type) {
    if (type == DeliveryType.pickup) return 0;
    if (subtotal >= 5000000) return 0;
    return type == DeliveryType.express ? 45000 : 25000;
  }

  int total(DeliveryType type) => subtotal + deliveryFee(type);

  int quantityOf(String productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line.quantity;
    }
    return 0;
  }
}

// ---------------------------------------------------------------------------
// Buyurtma
// ---------------------------------------------------------------------------

enum OrderStatus {
  pending('Yangi'),
  confirmed('Tasdiqlandi'),
  packing('Yig\u2018ilmoqda'),
  shipping('Yo\u2018lda'),
  delivered('Yetkazildi'),
  cancelled('Bekor qilindi');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus fromName(String? name) => OrderStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => OrderStatus.pending,
      );

  bool get isFinal => this == delivered || this == cancelled;
}

enum DeliveryType {
  courier('Kuryer', 'Manzilingizga yetkazib beramiz'),
  express('Tezkor (2 soat)', 'Toshkent shahri bo\u2018ylab'),
  pickup('O\u2018zim olib ketaman', 'Do\u2018kondan olib ketish');

  const DeliveryType(this.label, this.hint);
  final String label;
  final String hint;

  static DeliveryType fromName(String? name) => DeliveryType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => DeliveryType.courier,
      );
}

enum PaymentMethod {
  cash('Naqd pul'),
  click('Click'),
  payme('Payme'),
  uzcard('Uzcard'),
  humo('Humo'),
  installment('Muddatli to\u2018lov');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromName(String? name) =>
      PaymentMethod.values.firstWhere(
        (m) => m.name == name,
        orElse: () => PaymentMethod.cash,
      );
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image = '',
  });

  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String image;

  int get total => price * quantity;

  Map<String, Object?> toMap(String orderId) => {
        'order_id': orderId,
        'product_id': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'image': image,
      };

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
        productId: '${map['product_id']}',
        name: '${map['name']}',
        price: (map['price'] as num?)?.toInt() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        image: '${map['image'] ?? ''}',
      );
}

class Order {
  const Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryType,
    required this.paymentMethod,
    required this.customerName,
    required this.phone,
    required this.address,
    this.comment = '',
  });

  final String id;
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final String customerName;
  final String phone;
  final String address;
  final String comment;

  int get total => subtotal + deliveryFee;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Buyurtma raqami: TB-0042 ko'rinishida.
  String get number {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    final tail = digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    return 'TB-${tail.padLeft(4, '0')}';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'delivery_type': deliveryType.name,
        'payment_method': paymentMethod.name,
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'comment': comment,
      };

  factory Order.fromMap(Map<String, Object?> map, List<OrderItem> items) =>
      Order(
        id: '${map['id']}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (map['created_at'] as num?)?.toInt() ?? 0),
        status: OrderStatus.fromName(map['status'] as String?),
        items: items,
        subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
        deliveryFee: (map['delivery_fee'] as num?)?.toInt() ?? 0,
        deliveryType: DeliveryType.fromName(map['delivery_type'] as String?),
        paymentMethod: PaymentMethod.fromName(map['payment_method'] as String?),
        customerName: '${map['customer_name'] ?? ''}',
        phone: '${map['phone'] ?? ''}',
        address: '${map['address'] ?? ''}',
        comment: '${map['comment'] ?? ''}',
      );
}

// ---------------------------------------------------------------------------
// Foydalanuvchi
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = 'Toshkent',
  });

  static const String localId = 'me';

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;

  bool get isFilled => name.trim().isNotEmpty && phone.trim().isNotEmpty;

  /// Avatar uchun bosh harflar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'TB';
    if (parts.length == 1) return parts.first.head(2);
    return '${parts.first.head(1)}${parts.elementAt(1).head(1)}';
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        city: city ?? this.city,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
      };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
        id: '${map['id']}',
        name: '${map['name'] ?? ''}',
        phone: '${map['phone'] ?? ''}',
        email: '${map['email'] ?? ''}',
        address: '${map['address'] ?? ''}',
        city: '${map['city'] ?? 'Toshkent'}',
      );
}

extension _FirstChars on String {
  String head(int count) {
    final upper = toUpperCase();
    return upper.length <= count ? upper : upper.substring(0, count);
  }
}

// ---------------------------------------------------------------------------
// Sharh
// ---------------------------------------------------------------------------

class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.author,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String author;
  final int rating;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'author': author,
        'rating': rating,
        'text': text,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Review.fromMap(Map<String, Object?> map) => Review(
        id: '${map['id']}',
        productId: '${map['product_id']}',
        author: '${map['author'] ?? ''}',
        rating: (map['rating'] as num?)?.toInt() ?? 5,
        text: '${map['text'] ?? ''}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (map['created_at'] as num?)?.toInt() ?? 0),
      );
}

// ---------------------------------------------------------------------------
// Kompyuter yig'ilmasi
// ---------------------------------------------------------------------------

class PcBuild {
  const PcBuild({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.productIds,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// {slot: productId} — masalan {"cpu": "p-cpu-1"}.
  final Map<String, String> productIds;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
        'items': jsonEncode(productIds),
      };

  factory PcBuild.fromMap(Map<String, Object?> map) {
    Map<String, String> items = {};
    final raw = map['items'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          items = decoded.map((k, v) => MapEntry('$k', '$v'));
        }
      } catch (_) {
        items = {};
      }
    }
    return PcBuild(
      id: '${map['id']}',
      name: '${map['name'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as num?)?.toInt() ?? 0),
      productIds: items,
    );
  }
}

// ---------------------------------------------------------------------------
// TEXNO AI suhbati
// ---------------------------------------------------------------------------

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.productIds = const [],
  });

  final int id;

  /// 'user' yoki 'ai'.
  final String role;
  final String text;
  final DateTime createdAt;
  final List<String> productIds;

  bool get isUser => role == 'user';

  Map<String, Object?> toMap() => {
        if (id > 0) 'id': id,
        'role': role,
        'text': text,
        'created_at': createdAt.millisecondsSinceEpoch,
        'product_ids': productIds.join(','),
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: (map['id'] as num?)?.toInt() ?? 0,
        role: '${map['role'] ?? 'ai'}',
        text: '${map['text'] ?? ''}',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (map['created_at'] as num?)?.toInt() ?? 0),
        productIds: '${map['product_ids'] ?? ''}'
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Filtr / saralash
// ---------------------------------------------------------------------------

enum SortOption {
  popular('Ommabop'),
  priceAsc('Avval arzon'),
  priceDesc('Avval qimmat'),
  rating('Reyting bo\u2018yicha'),
  newest('Yangi kelganlar'),
  discount('Chegirma bo\u2018yicha');

  const SortOption(this.label);
  final String label;
}

class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.query = '',
    this.brands = const {},
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.onlyInStock = false,
    this.onlyDiscount = false,
    this.sort = SortOption.popular,
  });

  final String? categoryId;
  final String query;
  final Set<String> brands;
  final int? minPrice;
  final int? maxPrice;
  final double minRating;
  final bool onlyInStock;
  final bool onlyDiscount;
  final SortOption sort;

  bool get hasActiveFilters =>
      brands.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minRating > 0 ||
      onlyInStock ||
      onlyDiscount;

  int get activeCount =>
      (brands.isEmpty ? 0 : 1) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (onlyInStock ? 1 : 0) +
      (onlyDiscount ? 1 : 0);

  ProductFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? query,
    Set<String>? brands,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    double? minRating,
    bool? onlyInStock,
    bool? onlyDiscount,
    SortOption? sort,
  }) =>
      ProductFilter(
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        query: query ?? this.query,
        brands: brands ?? this.brands,
        minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
        maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
        minRating: minRating ?? this.minRating,
        onlyInStock: onlyInStock ?? this.onlyInStock,
        onlyDiscount: onlyDiscount ?? this.onlyDiscount,
        sort: sort ?? this.sort,
      );

  ProductFilter cleared() => ProductFilter(
        categoryId: categoryId,
        query: query,
        sort: sort,
      );
}
