import '../database/app_database.dart';

/// Mahsulotlar ombori.
///
/// Hozircha Drift (lokal SQLite) asosida ishlaydi. Keyinchalik server
/// ulansa, faqat shu klassning REST implementatsiyasini almashtirish
/// kifoya (Repository pattern).
abstract class ProductRepository {
  Stream<List<Product>> watchAll();
  Future<List<Product>> getAll();
  Stream<Product?> watchById(String id);
  Future<Product?> getById(String id);
  Future<List<Product>> search(String query);
  Future<List<String>> brands();
}

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<Product>> watchAll() => db.select(db.products).watch();

  @override
  Future<List<Product>> getAll() => db.select(db.products).get();

  @override
  Stream<Product?> watchById(String id) {
    final query = db.select(db.products)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<Product?> getById(String id) async {
    final query = db.select(db.products)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  /// Lokal qidiruv: mahsulot nomi, brend, kategoriya va xususiyatlar bo'yicha.
  /// Internet talab qilmaydi. Masalan: "RTX 5070" -> mos videokartalar.
  @override
  Future<List<Product>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final products = await getAll();
    final categoryNames = {
      for (final c in await db.select(db.categories).get()) c.id: c.name,
    };

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return [];

    final results = products.where((p) {
      final haystack =
          '${p.name} ${p.brand} ${p.description} ${categoryNames[p.categoryId] ?? ''} ${p.specsJson}'
              .toLowerCase();
      return tokens.every((t) => haystack.contains(t));
    }).toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return results;
  }

  @override
  Future<List<String>> brands() async {
    final products = await getAll();
    final brands = products.map((p) => p.brand).toSet().toList()..sort();
    return brands;
  }
}
