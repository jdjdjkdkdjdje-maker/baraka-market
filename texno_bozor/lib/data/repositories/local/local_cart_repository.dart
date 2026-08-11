import 'package:sqflite/sqflite.dart';

import '../../local/app_database.dart';
import '../../models/models.dart';
import '../repositories.dart';

/// Savat ombori — lokal SQLite implementatsiyasi.
///
/// Savat telefon xotirasida saqlanadi: ilova yopilib qayta ochilsa ham
/// mahsulotlar joyida qoladi.
class LocalCartRepository implements CartRepository {
  LocalCartRepository(this.appDb, this.products);

  final AppDatabase appDb;
  final ProductRepository products;

  Database get _db => appDb.db;

  @override
  Future<Cart> getCart() async {
    final rows = await _db.query('cart_items', orderBy: 'added_at ASC');
    if (rows.isEmpty) return Cart.empty;

    final ids = rows.map((r) => '${r['product_id']}').toList();
    final found = await products.getByIds(ids);
    final byId = {for (final p in found) p.id: p};

    final lines = <CartLine>[];
    for (final row in rows) {
      final product = byId['${row['product_id']}'];
      if (product == null) continue; // mahsulot katalogdan o'chirilgan
      final qty = (row['quantity'] as num?)?.toInt() ?? 1;
      lines.add(CartLine(product: product, quantity: qty));
    }
    return Cart(lines);
  }

  @override
  Future<void> add(String productId, {int quantity = 1}) async {
    if (quantity <= 0) return;
    final existing = await _db.query('cart_items',
        where: 'product_id = ?', whereArgs: [productId], limit: 1);

    if (existing.isEmpty) {
      await _db.insert('cart_items', {
        'product_id': productId,
        'quantity': quantity,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
      return;
    }
    final current = (existing.first['quantity'] as num?)?.toInt() ?? 0;
    await setQuantity(productId, current + quantity);
  }

  @override
  Future<void> setQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await remove(productId);
      return;
    }
    // Ombordagi miqdordan oshib ketmasin.
    final product = await products.getById(productId);
    final limited = product == null || product.stock <= 0
        ? quantity
        : quantity.clamp(1, product.stock);

    final updated = await _db.update(
      'cart_items',
      {'quantity': limited},
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    if (updated == 0) {
      await _db.insert('cart_items', {
        'product_id': productId,
        'quantity': limited,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Future<void> remove(String productId) async {
    await _db
        .delete('cart_items', where: 'product_id = ?', whereArgs: [productId]);
  }

  @override
  Future<void> clear() async {
    await _db.delete('cart_items');
  }
}
