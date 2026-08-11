import 'package:drift/drift.dart';

import '../../core/utils/pricing.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import 'cart_repository.dart';

/// Buyurtma ombori.
///
/// Hozircha buyurtmalar lokal tarix sifatida saqlanadi. Server ulansa
/// REST implementatsiya bilan almashtiriladi.
abstract class OrderRepository {
  Stream<List<Order>> watchAll();
  Stream<Order?> watchById(String id);
  Stream<List<OrderItem>> watchItems(String orderId);

  /// Savatdan buyurtma yaratadi: savatni tozalaydi va ombordan ayiradi.
  Future<Order> createFromCart({
    required String address,
    required PaymentMethod payment,
    required DeliveryMethod delivery,
    required String customerName,
    required String customerPhone,
  });

  Future<void> updateStatus(String orderId, OrderStatus status);
}

class DriftOrderRepository implements OrderRepository {
  DriftOrderRepository(this.db, this.cart);

  final AppDatabase db;
  final CartRepository cart;

  @override
  Stream<List<Order>> watchAll() {
    final query = db.select(db.orders)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  @override
  Stream<Order?> watchById(String id) {
    final query = db.select(db.orders)..where((t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Stream<List<OrderItem>> watchItems(String orderId) {
    final query = db.select(db.orderItems)
      ..where((t) => t.orderId.equals(orderId));
    return query.watch();
  }

  @override
  Future<Order> createFromCart({
    required String address,
    required PaymentMethod payment,
    required DeliveryMethod delivery,
    required String customerName,
    required String customerPhone,
  }) async {
    final items = await cart.getItems();
    if (items.isEmpty) {
      throw StateError('Savat bo\u2018sh');
    }

    final totals = calcOrderTotals(
      lines: [
        for (final entry in items)
          (
            price: entry.product.price,
            oldPrice: entry.product.oldPrice,
            qty: entry.qty,
          ),
      ],
      delivery: delivery,
    );
    final subtotal = totals.subtotal;
    final discount = totals.discount;
    final deliveryFee = totals.deliveryFee;
    final total = totals.total;
    final now = DateTime.now().millisecondsSinceEpoch;
    final order = Order(
      id: 'ORD-${now.toRadixString(36).toUpperCase()}',
      createdAt: now,
      status: OrderStatus.fresh.name,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      address: address,
      paymentMethod: payment.name,
      deliveryMethod: delivery.name,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    await db.transaction(() async {
      await db.into(db.orders).insert(order);
      for (final entry in items) {
        await db.into(db.orderItems).insert(
              OrderItemsCompanion.insert(
                orderId: order.id,
                productId: entry.product.id,
                name: entry.product.name,
                emoji: Value(entry.product.emoji),
                price: entry.product.price,
                qty: entry.qty,
              ),
            );
        // Ombordan ayirish.
        final newStock = (entry.product.stock - entry.qty).clamp(0, 999999).toInt();
        await (db.update(db.products)
              ..where((t) => t.id.equals(entry.product.id)))
            .write(ProductsCompanion(stock: Value(newStock)));
      }
      await db.delete(db.cartItems).go();
    });

    return order;
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await (db.update(db.orders)..where((t) => t.id.equals(orderId)))
        .write(OrdersCompanion(status: Value(status.name)));
  }
}
