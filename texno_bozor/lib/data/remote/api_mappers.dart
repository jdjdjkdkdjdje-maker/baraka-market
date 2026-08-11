import '../database/app_database.dart';

/// JSON <-> lokal model konvertorlari.
///
/// Server (NestJS + PostgreSQL) qaytargan JSON shu yerda bitta joyda
/// modelga aylantiriladi. Server maydon nomlari o'zgarsa — faqat shu fayl
/// tahrirlanadi.
class ApiMappers {
  ApiMappers._();

  static int _int(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round() ?? fallback;
    return fallback;
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    final parsed = _int(v, -1);
    return parsed < 0 ? null : parsed;
  }

  static double _double(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _str(dynamic v, [String fallback = '']) =>
      v == null ? fallback : v.toString();

  static int _millis(dynamic v) {
    if (v == null) return DateTime.now().millisecondsSinceEpoch;
    if (v is int) return v;
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
      return int.tryParse(v) ?? DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  static String _specs(dynamic v) {
    if (v == null) return '{}';
    if (v is String) return v.isEmpty ? '{}' : v;
    if (v is Map) {
      final buffer = StringBuffer('{');
      var first = true;
      v.forEach((key, value) {
        if (!first) buffer.write(',');
        first = false;
        buffer.write('"${_escape(key.toString())}":"${_escape(value.toString())}"');
      });
      buffer.write('}');
      return buffer.toString();
    }
    return '{}';
  }

  static String _escape(String s) =>
      s.replaceAll('\\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

  // ------------------------------------------------------------- CATEGORY

  static Category category(Map<String, dynamic> json) {
    return Category(
      id: _str(json['id']),
      name: _str(json['name']),
      icon: _str(json['icon'], 'device'),
      sortOrder: _int(json['sortOrder'] ?? json['sort_order']),
    );
  }

  // -------------------------------------------------------------- PRODUCT

  static Product product(Map<String, dynamic> json) {
    return Product(
      id: _str(json['id']),
      name: _str(json['name']),
      brand: _str(json['brand']),
      categoryId: _str(json['categoryId'] ?? json['category_id']),
      price: _int(json['price']),
      oldPrice: _intOrNull(json['oldPrice'] ?? json['old_price']),
      rating: _double(json['rating']),
      reviewsCount: _int(json['reviewsCount'] ?? json['reviews_count']),
      stock: _int(json['stock']),
      warranty: _str(json['warranty'], '12 oy kafolat'),
      description: _str(json['description']),
      specsJson: _specs(json['specs'] ?? json['specsJson'] ?? json['specs_json']),
      emoji: _str(json['emoji'], '\u{1F4E6}'),
      imageUrl: json['imageUrl'] == null && json['image_url'] == null
          ? null
          : _str(json['imageUrl'] ?? json['image_url']),
      popularity: _int(json['popularity']),
      createdAt: _millis(json['createdAt'] ?? json['created_at']),
      isTop: (json['isTop'] == true || json['is_top'] == true)
          ? 1
          : _int(json['isTop'] ?? json['is_top']),
    );
  }

  static Map<String, dynamic> productToJson(Product p) => {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'categoryId': p.categoryId,
        'price': p.price,
        'oldPrice': p.oldPrice,
        'rating': p.rating,
        'reviewsCount': p.reviewsCount,
        'stock': p.stock,
        'warranty': p.warranty,
        'description': p.description,
        'specs': p.specsJson,
        'emoji': p.emoji,
        'imageUrl': p.imageUrl,
        'popularity': p.popularity,
        'isTop': p.isTop == 1,
      };

  // ----------------------------------------------------------------- USER

  static User user(Map<String, dynamic> json) {
    return User(
      id: _str(json['id']),
      name: _str(json['name']),
      phone: _str(json['phone']),
      avatarEmoji: _str(json['avatarEmoji'] ?? json['avatar_emoji'], '\u{1F464}'),
      address: _str(json['address']),
      createdAt: _millis(json['createdAt'] ?? json['created_at']),
    );
  }

  static Map<String, dynamic> userToJson(User u) => {
        'id': u.id,
        'name': u.name,
        'phone': u.phone,
        'avatarEmoji': u.avatarEmoji,
        'address': u.address,
      };

  // ---------------------------------------------------------------- ORDER

  static Order order(Map<String, dynamic> json) {
    return Order(
      id: _str(json['id']),
      createdAt: _millis(json['createdAt'] ?? json['created_at']),
      status: _str(json['status'], 'fresh'),
      subtotal: _int(json['subtotal']),
      discount: _int(json['discount']),
      deliveryFee: _int(json['deliveryFee'] ?? json['delivery_fee']),
      total: _int(json['total']),
      address: _str(json['address']),
      paymentMethod: _str(json['paymentMethod'] ?? json['payment_method'], 'cash'),
      deliveryMethod:
          _str(json['deliveryMethod'] ?? json['delivery_method'], 'standard'),
      customerName: _str(json['customerName'] ?? json['customer_name']),
      customerPhone: _str(json['customerPhone'] ?? json['customer_phone']),
    );
  }

  static List<Map<String, dynamic>> listOf(dynamic data) {
    // Server javobi {data: [...]}, {items: [...]} yoki to'g'ridan-to'g'ri [...]
    final raw = data is Map
        ? (data['data'] ?? data['items'] ?? data['results'] ?? const [])
        : data;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Map<String, dynamic>? objectOf(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }
}
