import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ui_widgets.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderStream =
        ref.read(orderRepositoryProvider).watchById(orderId);

    return Scaffold(
      body: StreamBuilder(
        stream: orderStream,
        builder: (context, snapshot) {
          final order = snapshot.data;
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Buyurtmangiz qabul qilindi!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Buyurtma raqami: $orderId',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 13.5),
                    ),
                    if (order != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Summa: ${formatSum(order.total)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Buyurtmalar bo\u2018limidan holatini kuzatishingiz mumkin. Hozircha buyurtmalar lokal tarix sifatida saqlanadi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: GradientBox(
                        onTap: () => context.go('/orders'),
                        child: const Center(
                          child: Text(
                            'Buyurtmalarim',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Bosh sahifa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
