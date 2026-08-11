import 'package:drift/drift.dart';

import '../../../core/utils/async_utils.dart';
import '../../database/app_database.dart';
import '../../remote/api_client.dart';
import '../../remote/api_mappers.dart';
import '../product_repository.dart';

/// Mahsulotlar ombori — REST API (PostgreSQL) implementatsiyasi.
///
/// Offline-first: serverdan kelgan ma'lumot lokal SQLite'ga keshlanadi,
/// internet bo'lmasa lokal keshdan o'qiladi. Shu sababli ekranlar hech qanday
/// o'zgarishsiz ishlayveradi.
///
/// Kutilayotgan endpointlar:
///   GET /products            -> [{id, name, brand, categoryId, price, ...}]
///   GET /products/:id        -> {id, ...}
///   GET /products?search=... -> [...]
///   GET /products/brands     -> ["Apple", "Samsung", ...]
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this.api, this.db, {ProductRepository? cache})
      : cache = cache ?? DriftProductRepository(db);

  final ApiClient api;
  final AppDatabase db;

  /// Lokal kesh (offline fallback).
  final ProductRepository cache;

  Future<void> _cacheAll(List<Product> products) async {
    if (products.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.products, products);
    });
  }

  Future<List<Product>> _fetchAll() async {
    final data = await api.get('/products');
    final products = ApiMappers.listOf(data).map(ApiMappers.product).toList();
    await _cacheAll(products);
    return products;
  }

  @override
  Stream<List<Product>> watchAll() async* {
    // Fon rejimida serverdan yangilash (xato bo'lsa jim o'tadi).
    // Avval ishga tushiriladi, chunki quyidagi stream tugamaydi.
    fireAndForget(_fetchAll);
    // Kesh oqimi — ekran darhol to'ladi, server javobi kelgach yangilanadi.
    yield* cache.watchAll();
  }

  @override
  Future<List<Product>> getAll() async {
    try {
      return await _fetchAll();
    } on ApiException {
      return cache.getAll();
    }
  }

  @override
  Stream<Product?> watchById(String id) => cache.watchById(id);

  @override
  Future<Product?> getById(String id) async {
    try {
      final data = await api.get('/products/$id');
      final json = ApiMappers.objectOf(data);
      if (json == null) return cache.getById(id);
      final product = ApiMappers.product(json);
      await _cacheAll([product]);
      return product;
    } on ApiException {
      return cache.getById(id);
    }
  }

  @override
  Future<List<Product>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final data = await api.get('/products', query: {'search': q});
      final products = ApiMappers.listOf(data).map(ApiMappers.product).toList();
      await _cacheAll(products);
      return products;
    } on ApiException {
      return cache.search(q);
    }
  }

  @override
  Future<List<String>> brands() async {
    try {
      final data = await api.get('/products/brands');
      final raw = data is Map ? data['data'] : data;
      if (raw is List) {
        return raw.map((e) => e.toString()).toList()..sort();
      }
      return cache.brands();
    } on ApiException {
      return cache.brands();
    }
  }
}
