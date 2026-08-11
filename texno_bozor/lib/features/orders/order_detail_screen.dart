import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import 'orders_screen.dart';

/// BUYURTMA tafsiloti va holat kuzatuvi.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  static const List<OrderStatus> _flow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.packing,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(orderAsync.value?.number ?? 'Buyurtma')),
      body: orderAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
        data: (order) {
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Buyurtma topilmadi',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _statusCard(order),
              const SizedBox(height: 16),
              _section('Mahsulotlar', _items(context, order)),
              const SizedBox(height: 16),
              _section('Yetkazib berish', _delivery(order)),
              const SizedBox(height: 16),
              _section('To\u2018lov', _payment(order)),
              const SizedBox(height: 20),
              if (!order.status.isFinal)
                OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref, order),
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.danger),
                  label: const Text(
                    'Buyurtmani bekor qilish',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(Order order) {
    final color = OrdersScreen.statusColor(order.status);
    final currentIndex = _flow.indexOf(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(OrdersScreen.statusIcon(order.status), color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      Format.dateTime(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < _flow.length; i++)
              _step(
                label: _flow[i].label,
                done: i <= currentIndex,
                isLast: i == _flow.length - 1,
                color: color,
              ),
          ],
        ],
      ),
    );
  }

  Widget _step({
    required String label,
    required bool done,
    required bool isLast,
    required Color color,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : AppColors.surfaceHigh,
                  border: Border.all(
                    color: done ? color : AppColors.border,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? color : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                color: done ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _items(BuildContext context, Order order) {
    return Column(
      children: [
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.of(context)
                  .pushNamed('/product', arguments: item.productId),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: AppImage(source: item.image, radius: 8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.quantity} × ${Format.price(item.price)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Format.price(item.total),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Divider(height: 12),
        const SizedBox(height: 10),
        _row('Mahsulotlar', Format.price(order.subtotal)),
        const SizedBox(height: 6),
        _row(
          'Yetkazish',
          order.deliveryFee == 0 ? 'Bepul' : Format.price(order.deliveryFee),
        ),
        const SizedBox(height: 10),
        _row('Jami', Format.price(order.total), bold: true),
      ],
    );
  }

  Widget _delivery(Order order) {
    return Column(
      children: [
        _row('Usul', order.deliveryType.label),
        const SizedBox(height: 8),
        _row('Qabul qiluvchi', order.customerName),
        const SizedBox(height: 8),
        _row('Telefon', Format.phone(order.phone)),
        const SizedBox(height: 8),
        _row('Manzil', order.address, multiline: true),
        if (order.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          _row('Izoh', order.comment, multiline: true),
        ],
      ],
    );
  }

  Widget _payment(Order order) => _row('Usul', order.paymentMethod.label);

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              color: bold ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: multiline ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: bold ? 17 : 13.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buyurtmani bekor qilish'),
        content: Text('${order.number} raqamli buyurtma bekor qilinsinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo\u2018q'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ha, bekor qilish',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(ordersProvider.notifier).cancel(order.id);
    ref.invalidate(orderByIdProvider(order.id));
    ref.invalidate(allProductsProvider);
    if (context.mounted) showAppSnack(context, 'Buyurtma bekor qilindi');
  }
}
