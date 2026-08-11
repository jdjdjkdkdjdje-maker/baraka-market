import '../../../core/utils/async_utils.dart';
import '../../database/app_database.dart';
import '../../remote/api_client.dart';
import '../../remote/api_mappers.dart';
import '../category_repository.dart';

/// Kategoriyalar ombori — REST API implementatsiyasi (keshlash bilan).
///
/// Kutilayotgan endpoint: GET /categories -> [{id, name, icon, sortOrder}]
class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this.api, this.db, {CategoryRepository? cache})
      : cache = cache ?? DriftCategoryRepository(db);

  final ApiClient api;
  final AppDatabase db;
  final CategoryRepository cache;

  Future<void> _refresh() async {
    try {
      final data = await api.get('/categories');
      final categories =
          ApiMappers.listOf(data).map(ApiMappers.category).toList();
      if (categories.isEmpty) return;
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.categories, categories);
      });
    } on ApiException {
      // Offline — lokal kesh ishlatiladi.
    }
  }

  @override
  Stream<List<Category>> watchAll() async* {
    fireAndForget(_refresh);
    yield* cache.watchAll();
  }

  @override
  Future<Category?> getById(String id) async {
    await _refresh();
    return cache.getById(id);
  }
}
