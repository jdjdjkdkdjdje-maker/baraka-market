import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Sevimlilar ombori.
abstract class FavoritesRepository {
  Stream<Set<String>> watchIds();
  Stream<List<Product>> watchProducts();
  Future<bool> isFavorite(String productId);
  Future<void> toggle(String productId);
}

class DriftFavoritesRepository implements FavoritesRepository {
  DriftFavoritesRepository(this.db);

  final AppDatabase db;

  @override
  Stream<Set<String>> watchIds() {
    return db
        .select(db.favorites)
        .watch()
        .map((rows) => rows.map((r) => r.productId).toSet());
  }

  @override
  Stream<List<Product>> watchProducts() {
    final query = db.select(db.favorites).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.favorites.productId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(db.favorites.addedAt)]);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(db.products)).toList());
  }

  @override
  Future<bool> isFavorite(String productId) async {
    final row = await (db.select(db.favorites)
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> toggle(String productId) async {
    final exists = await isFavorite(productId);
    if (exists) {
      await (db.delete(db.favorites)
            ..where((t) => t.productId.equals(productId)))
          .go();
    } else {
      await db.into(db.favorites).insert(
            FavoritesCompanion.insert(
              productId: productId,
              addedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }
  }
}
