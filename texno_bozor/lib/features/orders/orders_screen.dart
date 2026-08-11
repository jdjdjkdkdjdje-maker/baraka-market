import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/models/enums.dart';

Color statusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.fresh:
      return AppColors.primary;
    case OrderStatus.preparing:
      return AppColors.warning;
    case OrderStatus.delivering:
      return AppColors.accent;
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.danger;
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Buyurtmalar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: orders.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Hali buyurtmalar yo\u2018q',
                    subtitle: 'Birinchi buyurtmangizni bering!',
                    actionLabel: 'Katalogga o\u2018tish',
                    onAction: () => context.go('/catalog'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final order = list[i];
                    final status = OrderStatus.fromName(order.status);
                    return Material(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/order/${order.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.id,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  StatusChip(
                                    label: status.label,
                                    color: statusColor(status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 14, color: AppColors.textDim),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatDateTime(DateTime
                                        .fromMillisecondsSinceEpoch(
                                            order.createdAt)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatSum(order.total),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => Center(child: Text('Xato: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
