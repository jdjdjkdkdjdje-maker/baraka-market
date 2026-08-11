import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/app_models.dart';

/// Savat ombori (to'liq lokal).
abstract class CartRepository {
  Stream<List<CartEntry>> watchItems();
  Stream<int> watchCount();
  Future<void> add(String productId, {int qty = 1});
  Future<void> setQty(String productId, int qty);
  Future<void> remove(String productId);
  Future<void> clear();
  Future<List<CartEntry>> getItems();
}

class DriftCartRepository implements CartRepository {
  DriftCartRepository(this.db);

  final AppDatabase db;

  CartEntry _entryFromRow(TypedResult row) {
    return CartEntry(
      product: row.readTable(db.products),
      qty: row.readTable(db.cartItems).qty,
    );
  }

  @override
  Stream<List<CartEntry>> watchItems() {
    final query = db.select(db.cartItems).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.cartItems.productId),
      ),
    ]);
    return query.watch().map((rows) => rows.map(_entryFromRow).toList());
  }

  @override
  Future<List<CartEntry>> getItems() async {
    final query = db.select(db.cartItems).join([
      innerJoin(
        db.products,
        db.products.id.equalsExp(db.cartItems.productId),
      ),
    ]);
    final rows = await query.get();
    return rows.map(_entryFromRow).toList();
  }

  @override
  Stream<int> watchCount() {
    return db
        .select(db.cartItems)
        .watch()
        .map((rows) => rows.length);
  }

  @override
  Future<void> add(String productId, {int qty = 1}) async {
    final existing = await (db.select(db.cartItems)
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();

    if (existing == null) {
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              productId: productId,
              qty: Value(qty),
              addedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } else {
      await (db.update(db.cartItems)
            ..where((t) => t.productId.equals(productId)))
          .write(CartItemsCompanion(qty: Value(existing.qty + qty)));
    }
  }

  @override
  Future<void> setQty(String productId, int qty) async {
    if (qty <= 0) {
      await remove(productId);
      return;
    }
    await (db.update(db.cartItems)
          ..where((t) => t.productId.equals(productId)))
        .write(CartItemsCompanion(qty: Value(qty)));
  }

  @override
  Future<void> remove(String productId) async {
    await (db.delete(db.cartItems)
          ..where((t) => t.productId.equals(productId)))
        .go();
  }

  @override
  Future<void> clear() async {
    await db.delete(db.cartItems).go();
  }
}
