import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';

/// Buyurtma muvaffaqiyatli qabul qilindi.
class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      body: SafeArea(
        child: order.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: '$e'),
          data: (data) {
            if (data == null) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Buyurtma topilmadi',
              );
            }
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 66,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Buyurtmangiz qabul qilindi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Buyurtma raqami: ${data.number}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Operatorlarimiz tez orada ${Format.phone(data.phone)} '
                    'raqamiga bog\u2018lanadi va buyurtmani tasdiqlaydi.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Column(
                      children: [
                        _row('Mahsulotlar', '${data.itemCount} dona'),
                        const SizedBox(height: 8),
                        _row('Yetkazish', data.deliveryType.label),
                        const SizedBox(height: 8),
                        _row('To\u2018lov', data.paymentMethod.label),
                        const Divider(height: 22),
                        _row('Jami', Format.price(data.total), bold: true),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      '/order-detail',
                      (route) => route.settings.name == '/',
                      arguments: data.id,
                    ),
                    child: const Text('Buyurtmani kuzatish'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Text('Bosh sahifaga qaytish'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13.5,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 13.5,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
