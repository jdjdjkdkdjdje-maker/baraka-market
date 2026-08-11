import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/pricing.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/models/enums.dart';

/// Buyurtma rasmiylashtirish: manzil -> yetkazish -> to'lov -> tasdiq.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  DeliveryMethod _delivery = DeliveryMethod.standard;
  PaymentMethod _payment = PaymentMethod.cash;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).currentUser;
    _addressController.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final address = _addressController.text.trim();
    if (address.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetkazib berish manzilini kiriting')),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final user = ref.read(appStateProvider).currentUser;
      final items = await ref.read(cartRepositoryProvider).getItems();

      final draftTotals = calcOrderTotals(
        lines: [
          for (final e in items)
            (price: e.product.price, oldPrice: e.product.oldPrice, qty: e.qty),
        ],
        delivery: _delivery,
      );

      // To'lov (hozircha lokal test rejimi).
      final paymentResult = await ref.read(paymentServiceProvider).pay(
            method: _payment,
            amount: draftTotals.total,
            orderId: 'draft',
          );
      if (!paymentResult.success) {
        throw StateError(paymentResult.message);
      }

      // Manzilni profilga saqlash.
      if (address != user?.address) {
        await ref.read(appStateProvider).updateProfile(address: address);
      }

      // Buyurtmani yaratish (savat avtomatik tozalanadi).
      final order = await ref.read(orderRepositoryProvider).createFromCart(
            address: address,
            payment: _payment,
            delivery: _delivery,
            customerName: user?.name ?? '',
            customerPhone: user?.phone ?? '',
          );

      if (!mounted) return;
      context.go('/order-success/${order.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(cartItemsProvider).valueOrNull ?? [];

    final totals = calcOrderTotals(
      lines: [
        for (final e in entries)
          (price: e.product.price, oldPrice: e.product.oldPrice, qty: e.qty),
      ],
      delivery: _delivery,
    );
    final subtotal = totals.subtotal;
    final discount = totals.discount;
    final deliveryFee = totals.deliveryFee;
    final total = totals.total;

    return Scaffold(
      appBar: AppBar(title: const Text('Buyurtma berish')),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Savat bo\u2018sh',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Manzil
                const Text(
                  'Yetkazib berish manzili',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'Shahar, ko\u2018cha, uy raqami. Masalan: Toshkent, Chilonzor 9, 12-uy',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Yetkazish usuli
                const Text(
                  'Yetkazib berish usuli',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...DeliveryMethod.values.map(
                  (d) => _OptionTile(
                    title: d.label,
                    subtitle: d.description,
                    trailing: calcDeliveryFee(
                              subtotal: subtotal,
                              delivery: d,
                            ) ==
                            0
                        ? const Text(
                            'Bepul',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          )
                        : Text(
                            formatSum(calcDeliveryFee(
                              subtotal: subtotal,
                              delivery: d,
                            )),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                    icon: d == DeliveryMethod.express
                        ? Icons.flash_on_rounded
                        : Icons.local_shipping_outlined,
                    selected: _delivery == d,
                    onTap: () => setState(() => _delivery = d),
                  ),
                ),
                const SizedBox(height: 20),

                // To'lov usuli
                const Text(
                  'To\u2018lov usuli',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...PaymentMethod.values.map(
                  (m) => _OptionTile(
                    title: m.label,
                    subtitle: m.description,
                    icon: _paymentIcon(m),
                    selected: _payment == m,
                    onTap: () => setState(() => _payment = m),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.warning),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hozircha to\u2018lov TEST rejimida ishlaydi. Real Click/Payme integratsiyasi server ulangach qo\u2018shiladi.',
                          style: TextStyle(
                              fontSize: 11.5, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Jami
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Mahsulotlar',
                              style: TextStyle(color: AppColors.textDim)),
                          const Spacer(),
                          Text(formatSum(subtotal),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Chegirma',
                              style: TextStyle(color: AppColors.textDim)),
                          const Spacer(),
                          Text(
                            discount > 0
                                ? '- ${formatSum(discount)}'
                                : '0 so\u2018m',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: discount > 0
                                  ? AppColors.success
                                  : AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Yetkazib berish',
                              style: TextStyle(color: AppColors.textDim)),
                          const Spacer(),
                          Text(
                            deliveryFee == 0 ? 'Bepul' : formatSum(deliveryFee),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: deliveryFee == 0
                                  ? AppColors.success
                                  : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Text(
                            'Jami:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          PriceText(total, fontSize: 19),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: GradientBox(
                    onTap: _processing ? null : _confirm,
                    child: Center(
                      child: _processing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text(
                              'Tasdiqlash va buyurtma berish',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.click:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.payme:
        return Icons.credit_card_rounded;
      case PaymentMethod.uzcard:
        return Icons.credit_score_rounded;
      case PaymentMethod.humo:
        return Icons.card_membership_rounded;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textDim,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textDim,
                      size: 22,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
