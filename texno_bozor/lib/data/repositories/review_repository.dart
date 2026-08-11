import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Sharhlar ombori. Sharh qo'shilganda mahsulot reytingi qayta hisoblanadi.
abstract class ReviewRepository {
  Stream<List<Review>> watchForProduct(String productId);
  Future<void> addReview({
    required String id,
    required String productId,
    required String userName,
    required double rating,
    required String text,
  });
}

class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<Review>> watchForProduct(String productId) {
    final query = db.select(db.reviews)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  @override
  Future<void> addReview({
    required String id,
    required String productId,
    required String userName,
    required double rating,
    required String text,
  }) async {
    await db.transaction(() async {
      await db.into(db.reviews).insert(
            ReviewsCompanion.insert(
              id: id,
              productId: productId,
              userName: userName,
              rating: rating,
              reviewText: Value(text),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      // Reytingni qayta hisoblash.
      final reviews = await (db.select(db.reviews)
            ..where((t) => t.productId.equals(productId)))
          .get();
      if (reviews.isNotEmpty) {
        final avg =
            reviews.fold<double>(0, (sum, r) => sum + r.rating) /
                reviews.length;
        await (db.update(db.products)
              ..where((t) => t.id.equals(productId)))
            .write(
          ProductsCompanion(
            rating: Value(avg),
            reviewsCount: Value(reviews.length),
          ),
        );
      }
    });
  }
}
