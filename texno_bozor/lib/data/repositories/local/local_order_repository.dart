import 'package:sqflite/sqflite.dart';

import '../../local/app_database.dart';
import '../../models/models.dart';
import '../repositories.dart';

/// Buyurtmalar ombori — lokal SQLite implementatsiyasi.
class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository(this.appDb, this.cart, this.products);

  final AppDatabase appDb;
  final CartRepository cart;
  final ProductRepository products;

  Database get _db => appDb.db;

  Future<List<OrderItem>> _itemsOf(String orderId) async {
    final rows = await _db
        .query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    return rows.map(OrderItem.fromMap).toList();
  }

  @override
  Future<List<Order>> getAll() async {
    final rows = await _db.query('orders', orderBy: 'created_at DESC');
    final orders = <Order>[];
    for (final row in rows) {
      orders.add(Order.fromMap(row, await _itemsOf('${row['id']}')));
    }
    return orders;
  }

  @override
  Future<Order?> getById(String id) async {
    final rows =
        await _db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Order.fromMap(rows.first, await _itemsOf(id));
  }

  @override
  Future<Order> createFromCart({
    required Cart cart,
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    required String customerName,
    required String phone,
    required String address,
    String comment = '',
  }) async {
    if (cart.isEmpty) {
      throw StateError('Savat bo\u2018sh — buyurtma yaratib bo\u2018lmaydi');
    }

    final now = DateTime.now();
    final id = 'ord-${now.millisecondsSinceEpoch}';
    final items = [
      for (final line in cart.lines)
        OrderItem(
          productId: line.product.id,
          name: line.product.name,
          price: line.product.price,
          quantity: line.quantity,
          image: line.product.image,
        ),
    ];

    final order = Order(
      id: id,
      createdAt: now,
      status: OrderStatus.pending,
      items: items,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee(deliveryType),
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      customerName: customerName,
      phone: phone,
      address: address,
      comment: comment,
    );

    await _db.transaction((txn) async {
      await txn.insert('orders', order.toMap());
      for (final item in items) {
        await txn.insert('order_items', item.toMap(id));
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      await txn.delete('cart_items');
    });

    return order;
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _db.update('orders', {'status': status.name},
        where: 'id = ?', whereArgs: [orderId]);
  }

  @override
  Future<void> cancel(String orderId) async {
    final order = await getById(orderId);
    if (order == null) return;
    if (order.status.isFinal) {
      throw StateError('Bu buyurtmani bekor qilib bo\u2018lmaydi');
    }

    await _db.transaction((txn) async {
      await txn.update('orders', {'status': OrderStatus.cancelled.name},
          where: 'id = ?', whereArgs: [orderId]);
      // Bekor qilinganda mahsulotlar omborga qaytariladi.
      for (final item in order.items) {
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }
}
