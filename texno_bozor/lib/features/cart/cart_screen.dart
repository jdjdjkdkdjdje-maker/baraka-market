import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';

/// SAVAT — mahsulotlar, miqdor, yakuniy summa.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final deliveryType = ref.watch(deliveryTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savat'),
        actions: [
          if ((cartAsync.value?.isNotEmpty) ?? false)
            IconButton(
              tooltip: 'Savatni tozalash',
              onPressed: () => _confirmClear(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: '$e',
          onRetry: () => ref.read(cartProvider.notifier).refresh(),
        ),
        data: (cart) {
          if (cart.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Savat bo\u2018sh',
              message: 'Katalogdan mahsulot tanlang va shu yerga qo\u2018shing',
              actionLabel: 'Katalogga o\u2018tish',
              onAction: () => Navigator.of(context).pushNamed('/catalog'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              for (final line in cart.lines) ...[
                _CartTile(line: line),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              _summary(context, cart, deliveryType),
            ],
          );
        },
      ),
      bottomNavigationBar: (cartAsync.value?.isNotEmpty ?? false)
          ? _checkoutBar(context, cartAsync.value!, deliveryType)
          : null,
    );
  }

  Widget _summary(BuildContext context, Cart cart, DeliveryType type) {
    final fee = cart.deliveryFee(type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          _row('Mahsulotlar (${cart.count} dona)',
              Format.price(cart.subtotal)),
          const SizedBox(height: 10),
          _row(
            'Yetkazib berish',
            fee == 0 ? 'Bepul' : Format.price(fee),
            valueColor: fee == 0 ? AppColors.success : null,
          ),
          if (cart.subtotal < 5000000 && type != DeliveryType.pickup) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Yana ${Format.price(5000000 - cart.subtotal)} '
                    'xarid qilsangiz yetkazish bepul',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          _row(
            'Jami',
            Format.price(cart.total(type)),
            bold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _checkoutBar(BuildContext context, Cart cart, DeliveryType type) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Jami',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  Format.price(cart.total(type)),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/checkout'),
                child: const Text('Rasmiylashtirish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Savatni tozalash'),
        content: const Text('Barcha mahsulotlar savatdan olib tashlansinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tozalash',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).clear();
      if (context.mounted) showAppSnack(context, 'Savat tozalandi');
    }
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = line.product;
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(cartProvider.notifier).remove(product.id);
        if (context.mounted) {
          showAppSnack(context, '${product.name} savatdan olindi');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed('/product', arguments: product.id),
              child: SizedBox(
                width: 82,
                height: 82,
                child: AppImage(source: product.image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Format.price(product.price),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        compact: true,
                        quantity: line.quantity,
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .increment(product.id),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .decrement(product.id),
                      ),
                      const Spacer(),
                      Text(
                        Format.price(line.total),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
