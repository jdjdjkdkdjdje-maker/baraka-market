import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/models/enums.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStream =
        ref.watch(orderRepositoryProvider).watchById(orderId);
    final itemsStream =
        ref.watch(orderRepositoryProvider).watchItems(orderId);

    return Scaffold(
      appBar: AppBar(title: Text('Buyurtma $orderId')),
      body: StreamBuilder<Order?>(
        stream: orderStream,
        builder: (context, orderSnap) {
          final order = orderSnap.data;
          if (order == null) return const LoadingView();

          final status = OrderStatus.fromName(order.status);
          final steps = status == OrderStatus.cancelled
              ? [OrderStatus.cancelled]
              : [
                  OrderStatus.fresh,
                  OrderStatus.preparing,
                  OrderStatus.delivering,
                  OrderStatus.delivered,
                ];
          final currentIndex =
              status == OrderStatus.cancelled ? 0 : steps.indexOf(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status timeline
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Holat: ',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        StatusChip(
                            label: status.label, color: statusColor(status)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (status == OrderStatus.cancelled)
                      const Text(
                        'Buyurtma bekor qilingan.',
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 13),
                      )
                    else
                      Row(
                        children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: i <= currentIndex
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                            Column(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: i <= currentIndex
                                        ? AppColors.primary
                                        : AppColors.cardLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: i <= currentIndex
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: i < currentIndex
                                      ? const Icon(Icons.check_rounded,
                                          size: 15,
                                          color: Color(0xFF04222B))
                                      : i == currentIndex
                                          ? const Icon(Icons.circle,
                                              size: 9,
                                              color: Color(0xFF04222B))
                                          : null,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  steps[i].label.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: i <= currentIndex
                                        ? AppColors.text
                                        : AppColors.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mahsulotlar
              StreamBuilder<List<OrderItem>>(
                stream: itemsStream,
                builder: (context, itemsSnap) {
                  final items = itemsSnap.data ?? [];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mahsulotlar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        for (final item in items)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text(item.emoji,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${item.qty} x ${formatSum(item.price)}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textDim),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatSum(item.price * item.qty),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Summalar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _row('Mahsulotlar', formatSum(order.subtotal)),
                    const SizedBox(height: 6),
                    _row(
                      'Chegirma',
                      order.discount > 0
                          ? '- ${formatSum(order.discount)}'
                          : '0 so\u2018m',
                    ),
                    const SizedBox(height: 6),
                    _row(
                      'Yetkazib berish',
                      order.deliveryFee == 0
                          ? 'Bepul'
                          : formatSum(order.deliveryFee),
                    ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        const Text('Jami',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        PriceText(order.total, fontSize: 17),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Ma'lumotlar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.person_outline_rounded,
                        order.customerName.isEmpty ? '-' : order.customerName),
                    const SizedBox(height: 8),
                    _infoRow(Icons.phone_outlined,
                        order.customerPhone.isEmpty ? '-' : order.customerPhone),
                    const SizedBox(height: 8),
                    _infoRow(Icons.location_on_outlined,
                        order.address.isEmpty ? '-' : order.address),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.payments_outlined,
                      PaymentMethod.fromName(order.paymentMethod).label,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.local_shipping_outlined,
                      DeliveryMethod.fromName(order.deliveryMethod).label,
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.schedule_rounded,
                      formatDateTime(
                          DateTime.fromMillisecondsSinceEpoch(order.createdAt)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Amallar
              if (status == OrderStatus.fresh ||
                  status == OrderStatus.preparing)
                OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Buyurtmani bekor qilish'),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
        const Spacer(),
        Text(value,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textDim),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Bekor qilinsinmi?'),
        content: const Text(
            'Buyurtmani bekor qilishni tasdiqlaysizmi? Bu amalni ortga qaytarib bo\u2018lmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Yo\u2018q'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(orderRepositoryProvider)
                  .updateStatus(orderId, OrderStatus.cancelled);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
  }
}
