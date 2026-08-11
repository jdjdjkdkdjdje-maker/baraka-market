import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Qidiruv tarixi va yaqinda ko'rilgan mahsulotlar.
abstract class HistoryRepository {
  Stream<List<SearchHistoryEntry>> watchSearchHistory();
  Future<void> addSearch(String query);
  Future<void> clearSearchHistory();

  Stream<List<Product>> watchRecentlyViewed();
  Future<void> addViewed(String productId);
}

class DriftHistoryRepository implements HistoryRepository {
  DriftHistoryRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<SearchHistoryEntry>> watchSearchHistory() {
    final query = db.select(db.searchHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(20);
    return query.watch();
  }

  @override
  Future<void> addSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    // Takroriy yozuvlarni olib tashlash.
    await (db.delete(db.searchHistory)
          ..where((t) => t.query.equals(q)))
        .go();
    await db.into(db.searchHistory).insert(
          SearchHistoryCompanion.insert(
            query: q,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );

    // 20 tadan ortiq saqlamaslik.
    final all = await (db.select(db.searchHistory)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (all.length > 20) {
      final oldIds = all.skip(20).map((e) => e.id).toList();
      await (db.delete(db.searchHistory)
            ..where((t) => t.id.isIn(oldIds)))
          .go();
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    await db.delete(db.searchHistory).go();
  }

  @override
  Stream<List<Product>> watchRecentlyViewed() {
    final query = db.select(db.recentlyViewed).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.recentlyViewed.productId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(db.recentlyViewed.viewedAt)])
      ..limit(10);
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(db.products)).toList());
  }

  @override
  Future<void> addViewed(String productId) async {
    await db.into(db.recentlyViewed).insert(
          RecentlyViewedCompanion.insert(
            productId: productId,
            viewedAt: DateTime.now().millisecondsSinceEpoch,
          ),
          mode: InsertMode.replace,
        );
  }
}
