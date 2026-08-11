import 'package:drift/drift.dart';

import '../database/app_database.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<Category?> getById(String id);
}

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<Category>> watchAll() {
    final query = db.select(db.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch();
  }

  @override
  Future<Category?> getById(String id) async {
    final query = db.select(db.categories)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }
}
