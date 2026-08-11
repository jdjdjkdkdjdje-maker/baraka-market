import 'package:drift/drift.dart';

import '../../../core/utils/async_utils.dart';
import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../remote/api_client.dart';
import '../../remote/api_mappers.dart';
import '../cart_repository.dart';
import '../order_repository.dart';

/// Buyurtmalar ombori — REST API implementatsiyasi.
///
/// Buyurtma serverga yuboriladi; muvaffaqiyatli javob lokal bazaga
/// keshlanadi. Server ishlamasa, buyurtma lokal tarzda yaratiladi va
/// keyinchalik sinxronlanishi mumkin (offline-first).
///
/// Kutilayotgan endpointlar:
///   GET   /orders           -> [{id, status, total, ...}]
///   GET   /orders/:id       -> {id, ..., items: [...]}
///   POST  /orders           {address, payment, delivery, items: [...]}
///   PATCH /orders/:id/status {status}
class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(
    this.api,
    this.db,
    this.cart, {
    OrderRepository? local,
  }) : local = local ?? DriftOrderRepository(db, cart);

  final ApiClient api;
  final AppDatabase db;
  final CartRepository cart;
  final OrderRepository local;

  Future<void> _refresh() async {
    final data = await api.get('/orders');
    final orders = ApiMappers.listOf(data).map(ApiMappers.order).toList();
    if (orders.isEmpty) return;
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.orders, orders);
    });
  }

  @override
  Stream<List<Order>> watchAll() async* {
    fireAndForget(_refresh);
    yield* local.watchAll();
  }

  @override
  Stream<Order?> watchById(String id) => local.watchById(id);

  @override
  Stream<List<OrderItem>> watchItems(String orderId) => local.watchItems(orderId);

  @override
  Future<Order> createFromCart({
    required String address,
    required PaymentMethod payment,
    required DeliveryMethod delivery,
    required String customerName,
    required String customerPhone,
  }) async {
    final items = await cart.getItems();

    try {
      final response = await api.post('/orders', body: {
        'address': address,
        'paymentMethod': payment.name,
        'deliveryMethod': delivery.name,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': [
          for (final e in items) {'productId': e.product.id, 'qty': e.qty},
        ],
      });
      final json = ApiMappers.objectOf(response);
      if (json != null && json['id'] != null) {
        final order = ApiMappers.order(json);
        // Serverdagi buyurtmani lokal bazaga yozamiz + savatni tozalaymiz.
        await db.transaction(() async {
          await db.into(db.orders).insertOnConflictUpdate(order);
          for (final e in items) {
            await db.into(db.orderItems).insert(
                  OrderItemsCompanion.insert(
                    orderId: order.id,
                    productId: e.product.id,
                    name: e.product.name,
                    emoji: Value(e.product.emoji),
                    price: e.product.price,
                    qty: e.qty,
                  ),
                );
          }
          await db.delete(db.cartItems).go();
        });
        return order;
      }
    } on ApiException {
      // Server ishlamasa — offline rejimda lokal buyurtma yaratiladi.
    }

    return local.createFromCart(
      address: address,
      payment: payment,
      delivery: delivery,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await local.updateStatus(orderId, status);
    fireAndForget(
      () => api.patch('/orders/$orderId/status', body: {'status': status.name}),
    );
  }
}
