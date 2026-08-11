import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/pricing.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/models/app_models.dart';
import '../../data/models/enums.dart';

/// Savat — to'liq lokal, ilova yopilgandan keyin ham saqlanadi.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Savat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: items.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Savat bo\u2018sh',
                    subtitle:
                        'Katalogdan yoqqan mahsulotlaringizni savatga qo\u2018shing',
                    actionLabel: 'Katalogga o\u2018tish',
                    onAction: () => context.go('/catalog'),
                  );
                }
                return _CartContent(entries: entries);
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

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.entries});

  final List<CartEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = calcOrderTotals(
      lines: [
        for (final e in entries)
          (price: e.product.price, oldPrice: e.product.oldPrice, qty: e.qty),
      ],
      delivery: DeliveryMethod.standard,
    );
    final subtotal = totals.subtotal;
    final discount = totals.discount;
    final delivery = totals.deliveryFee;
    final total = totals.total;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _CartItemTile(entry: entries[i]),
          ),
        ),

        // Jami bloki
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _SummaryRow(
                  label: 'Mahsulotlar summasi', value: formatSum(subtotal)),
              const SizedBox(height: 6),
              _SummaryRow(
                label: 'Chegirma',
                value: discount > 0 ? '- ${formatSum(discount)}' : '0 so\u2018m',
                valueColor:
                    discount > 0 ? AppColors.success : AppColors.textDim,
              ),
              const SizedBox(height: 6),
              _SummaryRow(
                label: 'Yetkazib berish',
                value: delivery == 0 ? 'Bepul' : formatSum(delivery),
                valueColor:
                    delivery == 0 ? AppColors.success : AppColors.text,
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Text(
                    'Jami:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  PriceText(total, fontSize: 19),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GradientBox(
                  onTap: () => context.push('/checkout'),
                  child: const Center(
                    child: Text(
                      'Buyurtma berish',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textDim),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.entry});

  final CartEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = entry.product;

    return Dismissible(
      key: ValueKey('cart_${product.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          ref.read(cartRepositoryProvider).remove(product.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 74,
                height: 74,
                child: ProductVisual(
                    product: product, height: 74, fontSize: 32),
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
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (product.oldPrice != null)
                    Text(
                      formatSum(product.oldPrice!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDim,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    formatSum(product.price),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: () => ref
                          .read(cartRepositoryProvider)
                          .setQty(product.id, entry.qty - 1),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${entry.qty}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      enabled: entry.qty < product.stock,
                      onTap: () => ref
                          .read(cartRepositoryProvider)
                          .setQty(product.id, entry.qty + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatSum(entry.total),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.enabled = true});

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withOpacity(0.14)
              : AppColors.border.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.textDim,
        ),
      ),
    );
  }
}
