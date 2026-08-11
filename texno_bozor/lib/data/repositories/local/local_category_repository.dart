import 'package:sqflite/sqflite.dart';

import '../../local/app_database.dart';
import '../../models/models.dart';
import '../repositories.dart';

/// Kategoriyalar ombori — lokal SQLite implementatsiyasi.
class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this.appDb);

  final AppDatabase appDb;

  Database get _db => appDb.db;

  @override
  Future<List<Category>> getAll() async {
    final rows = await _db.query('categories', orderBy: 'sort ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final rows = await _db.query('categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  @override
  Future<Map<String, int>> productCounts() async {
    final rows = await _db.rawQuery(
      'SELECT category_id, COUNT(*) AS cnt FROM products GROUP BY category_id',
    );
    return {
      for (final row in rows)
        '${row['category_id']}': (row['cnt'] as num?)?.toInt() ?? 0,
    };
  }
}
