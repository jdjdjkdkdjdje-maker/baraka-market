import 'package:sqflite/sqflite.dart';

import '../../local/app_database.dart';
import '../../models/models.dart';
import '../repositories.dart';

/// Mahsulotlar ombori — lokal SQLite implementatsiyasi (offline-first).
class LocalProductRepository implements ProductRepository {
  LocalProductRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  Future<List<Product>> _select(
    String where, {
    List<Object?> args = const [],
    String? orderBy,
    int? limit,
  }) async {
    final rows = await _db.query(
      'products',
      where: where.isEmpty ? null : where,
      whereArgs: where.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  @override
  Future<List<Product>> getAll() =>
      _select('', orderBy: 'popularity DESC, rating DESC');

  @override
  Future<Product?> getById(String id) async {
    final rows = await _db.query('products',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  @override
  Future<List<Product>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.query('products',
        where: 'id IN ($placeholders)', whereArgs: ids);
    final products = rows.map(Product.fromMap).toList();
    // Kiritilgan tartibni saqlaymiz.
    final byId = {for (final p in products) p.id: p};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Future<List<Product>> getByCategory(String categoryId) => _select(
        'category_id = ?',
        args: [categoryId],
        orderBy: 'popularity DESC',
      );

  @override
  Future<List<Product>> query(ProductFilter filter) async {
    final where = <String>[];
    final args = <Object?>[];

    if (filter.categoryId != null && filter.categoryId!.isNotEmpty) {
      where.add('category_id = ?');
      args.add(filter.categoryId);
    }
    if (filter.brands.isNotEmpty) {
      final placeholders = List.filled(filter.brands.length, '?').join(',');
      where.add('brand IN ($placeholders)');
      args.addAll(filter.brands);
    }
    if (filter.minPrice != null) {
      where.add('price >= ?');
      args.add(filter.minPrice);
    }
    if (filter.maxPrice != null) {
      where.add('price <= ?');
      args.add(filter.maxPrice);
    }
    if (filter.minRating > 0) {
      where.add('rating >= ?');
      args.add(filter.minRating);
    }
    if (filter.onlyInStock) {
      where.add('stock > 0');
    }
    if (filter.onlyDiscount) {
      where.add('old_price > price');
    }

    final rows = await _db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: _orderBy(filter.sort),
    );
    var products = rows.map(Product.fromMap).toList();

    final text = filter.query.trim();
    if (text.isNotEmpty) {
      final matched = await _matchText(products, text);
      products = matched;
    }
    return products;
  }

  static String _orderBy(SortOption sort) {
    switch (sort) {
      case SortOption.priceAsc:
        return 'price ASC';
      case SortOption.priceDesc:
        return 'price DESC';
      case SortOption.rating:
        return 'rating DESC, rating_count DESC';
      case SortOption.newest:
        return 'created_at DESC';
      case SortOption.discount:
        return '(CASE WHEN old_price > price '
            'THEN (old_price - price) * 100 / old_price ELSE 0 END) DESC';
      case SortOption.popular:
        return 'popularity DESC, rating DESC';
    }
  }

  /// Matn bo'yicha moslikni hisoblaydi: nom > brend > kategoriya > xususiyat.
  Future<List<Product>> _matchText(List<Product> source, String text) async {
    final q = text.toLowerCase().trim();
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return source;

    final categoryNames = <String, String>{};
    for (final row in await _db.query('categories')) {
      categoryNames['${row['id']}'] = '${row['name']}'.toLowerCase();
    }

    final scored = <({Product product, int score})>[];
    for (final p in source) {
      final name = p.name.toLowerCase();
      final brand = p.brand.toLowerCase();
      final category = categoryNames[p.categoryId] ?? '';
      final specs = p.specs.values.join(' ').toLowerCase();
      final haystack = '$name $brand $category $specs ${p.description.toLowerCase()}';

      // Har bir so'z topilishi shart (AND qidiruv).
      if (!tokens.every(haystack.contains)) continue;

      var score = 0;
      if (name.startsWith(q)) score += 100;
      if (name.contains(q)) score += 60;
      for (final t in tokens) {
        if (name.contains(t)) score += 20;
        if (brand.contains(t)) score += 12;
        if (category.contains(t)) score += 8;
        if (specs.contains(t)) score += 4;
      }
      score += p.popularity ~/ 10;
      scored.add((product: p, score: score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.product.popularity.compareTo(a.product.popularity);
    });
    return scored.map((e) => e.product).toList();
  }

  @override
  Future<List<Product>> search(String text) async {
    if (text.trim().isEmpty) return [];
    final all = await getAll();
    return _matchText(all, text);
  }

  @override
  Future<List<Product>> popular({int limit = 10}) =>
      _select('stock > 0', orderBy: 'popularity DESC', limit: limit);

  @override
  Future<List<Product>> newest({int limit = 10}) =>
      _select('', orderBy: 'created_at DESC', limit: limit);

  @override
  Future<List<Product>> discounted({int limit = 10}) => _select(
        'old_price > price',
        orderBy: '(old_price - price) * 100 / old_price DESC',
        limit: limit,
      );

  @override
  Future<List<Product>> similar(Product product, {int limit = 8}) async {
    final rows = await _db.query(
      'products',
      where: 'category_id = ? AND id != ?',
      whereArgs: [product.categoryId, product.id],
    );
    final products = rows.map(Product.fromMap).toList()
      ..sort((a, b) {
        final da = (a.price - product.price).abs();
        final db = (b.price - product.price).abs();
        return da.compareTo(db);
      });
    if (products.length <= limit) return products;
    return products.sublist(0, limit);
  }

  @override
  Future<List<String>> brands({String? categoryId}) async {
    final rows = await _db.query(
      'products',
      columns: ['DISTINCT brand'],
      where: categoryId == null ? null : 'category_id = ?',
      whereArgs: categoryId == null ? null : [categoryId],
      orderBy: 'brand ASC',
    );
    return rows
        .map((r) => '${r['brand']}')
        .where((b) => b.isNotEmpty)
        .toList();
  }

  @override
  Future<(int, int)> priceRange({String? categoryId}) async {
    final rows = await _db.rawQuery(
      'SELECT MIN(price) AS mn, MAX(price) AS mx FROM products'
      '${categoryId == null ? '' : ' WHERE category_id = ?'}',
      categoryId == null ? null : [categoryId],
    );
    if (rows.isEmpty) return (0, 0);
    final mn = (rows.first['mn'] as num?)?.toInt() ?? 0;
    final mx = (rows.first['mx'] as num?)?.toInt() ?? 0;
    return (mn, mx);
  }

  @override
  Future<void> decreaseStock(String productId, int quantity) async {
    await _db.rawUpdate(
      'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
      [quantity, productId],
    );
  }
}
