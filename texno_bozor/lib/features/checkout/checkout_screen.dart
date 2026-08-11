import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';

/// BUYURTMA RASMIYLASHTIRISH — manzil, yetkazish, to'lov.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();

  bool _submitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _prefill(AppUser user) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = user.name;
    _phoneController.text = user.phone.isEmpty ? '+998 ' : user.phone;
    _addressController.text = user.address;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider).value ?? Cart.empty;
    final deliveryType = ref.watch(deliveryTypeProvider);
    final payment = ref.watch(paymentMethodProvider);
    final user = ref.watch(userProvider).value;
    if (user != null) _prefill(user);

    if (cart.isEmpty && !_submitting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rasmiylashtirish')),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Savat bo\u2018sh',
          actionLabel: 'Katalogga o\u2018tish',
          onAction: () => Navigator.of(context).pushNamed('/catalog'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rasmiylashtirish')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _sectionTitle('Qabul qiluvchi'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ism familiya',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => (value == null || value.trim().length < 3)
                  ? 'Ismingizni to\u2018liq kiriting'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                LengthLimitingTextInputFormatter(17),
              ],
              decoration: const InputDecoration(
                labelText: 'Telefon raqam',
                hintText: '+998 90 123 45 67',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) => Format.isValidPhone(value ?? '')
                  ? null
                  : 'To\u2018g\u2018ri raqam kiriting: +998 XX XXX XX XX',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Yetkazib berish'),
            for (final type in DeliveryType.values)
              _optionTile(
                selected: deliveryType == type,
                title: type.label,
                subtitle: type.hint,
                trailing: type == DeliveryType.pickup
                    ? 'Bepul'
                    : cart.deliveryFee(type) == 0
                        ? 'Bepul'
                        : Format.price(cart.deliveryFee(type)),
                onTap: () =>
                    ref.read(deliveryTypeProvider.notifier).state = type,
              ),
            if (deliveryType != DeliveryType.pickup) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  hintText: 'Shahar, tuman, ko\u2018cha, uy',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (deliveryType == DeliveryType.pickup) return null;
                  return (value == null || value.trim().length < 6)
                      ? 'Manzilni to\u2018liq kiriting'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle('To\u2018lov usuli'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(method.label),
                    selected: payment == method,
                    onSelected: (_) => ref
                        .read(paymentMethodProvider.notifier)
                        .state = method,
                  ),
              ],
            ),
            if (payment != PaymentMethod.cash)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${payment.label} orqali to\u2018lov kuryer yetkazganda '
                        'yoki operator qo\u2018ng\u2018irog\u2018idan keyin '
                        'amalga oshiriladi.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            _sectionTitle('Izoh (ixtiyoriy)'),
            TextFormField(
              controller: _commentController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Kuryer uchun qo\u2018shimcha ma\u2018lumot',
              ),
            ),
            const SizedBox(height: 20),
            _orderSummary(cart, deliveryType),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    'Buyurtma berish · '
                    '${Format.price(cart.total(deliveryType))}',
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      );

  Widget _optionTile({
    required bool selected,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        leading: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: Text(
          trailing,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }

  Widget _orderSummary(Cart cart, DeliveryType type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          for (final line in cart.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${line.product.name} × ${line.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Format.price(line.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jami to\u2018lov',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(
                Format.price(cart.total(type)),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cart = ref.read(cartProvider).value ?? Cart.empty;
    if (cart.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final deliveryType = ref.read(deliveryTypeProvider);
      final order = await ref.read(ordersProvider.notifier).create(
            cart: cart,
            deliveryType: deliveryType,
            paymentMethod: ref.read(paymentMethodProvider),
            customerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: deliveryType == DeliveryType.pickup
                ? 'Do\u2018kondan olib ketish'
                : _addressController.text.trim(),
            comment: _commentController.text.trim(),
          );

      // Profil ma'lumotlarini eslab qolamiz.
      final user = ref.read(userProvider).value ??
          const AppUser(id: AppUser.localId);
      await ref.read(userProvider.notifier).save(user.copyWith(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: deliveryType == DeliveryType.pickup
                ? user.address
                : _addressController.text.trim(),
          ));

      await ref.read(cartProvider.notifier).refresh();
      ref.invalidate(allProductsProvider);
      ref.invalidate(popularProductsProvider);

      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed('/order-success', arguments: order.id);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        showAppSnack(context, 'Xatolik: $e', isError: true);
      }
    }
  }
}
