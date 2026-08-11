import '../../../core/utils/async_utils.dart';
import '../../database/app_database.dart';
import '../../models/app_models.dart';
import '../../remote/api_client.dart';
import '../cart_repository.dart';

/// Savat ombori — REST API implementatsiyasi.
///
/// Savat har doim lokal bazada yuritiladi (offline-first: internetsiz ham
/// mahsulot qo'shish ishlashi shart), o'zgarishlar esa fon rejimida serverga
/// sinxronlanadi. Internet qaytganda `sync()` chaqiriladi.
///
/// Kutilayotgan endpointlar:
///   GET    /cart                 -> [{productId, qty}]
///   POST   /cart      {productId, qty}
///   PATCH  /cart/:productId {qty}
///   DELETE /cart/:productId
///   DELETE /cart
class ApiCartRepository implements CartRepository {
  ApiCartRepository(this.api, this.db, {CartRepository? local})
      : local = local ?? DriftCartRepository(db);

  final ApiClient api;
  final AppDatabase db;

  /// Lokal manba — haqiqat manbai (source of truth) offline rejimda.
  final CartRepository local;

  @override
  Stream<List<CartEntry>> watchItems() => local.watchItems();

  @override
  Stream<int> watchCount() => local.watchCount();

  @override
  Future<List<CartEntry>> getItems() => local.getItems();

  @override
  Future<void> add(String productId, {int qty = 1}) async {
    await local.add(productId, qty: qty);
    fireAndForget(() => api.post('/cart', body: {
          'productId': productId,
          'qty': qty,
        }));
  }

  @override
  Future<void> setQty(String productId, int qty) async {
    await local.setQty(productId, qty);
    fireAndForget(() => qty <= 0
        ? api.delete('/cart/$productId')
        : api.patch('/cart/$productId', body: {'qty': qty}));
  }

  @override
  Future<void> remove(String productId) async {
    await local.remove(productId);
    fireAndForget(() => api.delete('/cart/$productId'));
  }

  @override
  Future<void> clear() async {
    await local.clear();
    fireAndForget(() => api.delete('/cart'));
  }

  /// Lokal savatni serverga to'liq yuklash (internet qaytganda).
  Future<void> sync() async {
    final items = await local.getItems();
    await api.put('/cart', body: {
      'items': [
        for (final e in items) {'productId': e.product.id, 'qty': e.qty},
      ],
    });
  }
}
