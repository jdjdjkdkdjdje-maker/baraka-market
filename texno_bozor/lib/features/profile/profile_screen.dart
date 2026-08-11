import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';

/// PROFIL — foydalanuvchi ma'lumotlari va bo'limlar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).value ??
        const AppUser(id: AppUser.localId);
    final activeOrders = ref.watch(activeOrdersCountProvider);
    final favorites = ref.watch(favoritesProvider).value?.length ?? 0;
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _profileCard(context, ref, user),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(
                context,
                icon: Icons.receipt_long_rounded,
                value: '$activeOrders',
                label: 'Faol buyurtma',
                onTap: () => Navigator.of(context).pushNamed('/orders'),
              ),
              const SizedBox(width: 10),
              _statCard(
                context,
                icon: Icons.favorite_rounded,
                value: '$favorites',
                label: 'Sevimlilar',
                onTap: () => Navigator.of(context).pushNamed('/favorites'),
              ),
              const SizedBox(width: 10),
              _statCard(
                context,
                icon: Icons.shopping_cart_rounded,
                value: '$cartCount',
                label: 'Savatda',
                onTap: () => Navigator.of(context).pushNamed('/cart'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _menuGroup([
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Buyurtmalarim',
              onTap: () => Navigator.of(context).pushNamed('/orders'),
            ),
            _MenuItem(
              icon: Icons.favorite_border_rounded,
              title: 'Sevimlilar',
              onTap: () => Navigator.of(context).pushNamed('/favorites'),
            ),
            _MenuItem(
              icon: Icons.memory_rounded,
              title: 'Kompyuter yig\u2018ish',
              onTap: () => Navigator.of(context).pushNamed('/pc-builder'),
            ),
            _MenuItem(
              icon: Icons.auto_awesome_rounded,
              title: 'TEXNO AI yordamchi',
              onTap: () => Navigator.of(context).pushNamed('/ai'),
            ),
          ]),
          const SizedBox(height: 12),
          _menuGroup([
            _MenuItem(
              icon: Icons.settings_outlined,
              title: 'Sozlamalar',
              onTap: () => Navigator.of(context).pushNamed('/settings'),
            ),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              title: 'Ilova haqida',
              onTap: () => _showAbout(context),
            ),
          ]),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'TEXNO BOZOR · 1.0.0\nOffline-first Flutter ilovasi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(BuildContext context, WidgetRef ref, AppUser user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.trim().isEmpty ? 'Mehmon' : user.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.phone.trim().isEmpty
                      ? 'Ma\u2018lumotlarni to\u2018ldiring'
                      : Format.phone(user.phone),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editProfile(context, ref, user),
            icon: const Icon(Icons.edit_outlined, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Icon(items[i].icon, size: 21, color: AppColors.accent),
              title: Text(
                items[i].title,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController =
        TextEditingController(text: user.phone.isEmpty ? '+998 ' : user.phone);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profilni tahrirlash',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ism familiya',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (ixtiyoriy)',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Saqlash'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;
    await ref.read(userProvider.notifier).save(user.copyWith(
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          email: emailController.text.trim(),
          address: addressController.text.trim(),
        ));
    if (context.mounted) showAppSnack(context, 'Profil saqlandi');
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TEXNO BOZOR haqida'),
        content: const Text(
          'TEXNO BOZOR — elektronika marketplace ilovasi.\n\n'
          'Barcha ma\u2018lumotlar telefoningizda saqlanadi: katalog, savat, '
          'buyurtmalar va sevimlilar internetsiz ishlaydi.\n\n'
          'Internet faqat TEXNO AI yordamchisi uchun kerak (u ham '
          'internetsiz oddiy rejimda javob beradi).\n\n'
          'Versiya: 1.0.0',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}
