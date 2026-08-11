import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';

const List<String> _avatarEmojis = [
  '\u{1F464}',
  '\u{1F60E}',
  '\u{1F9D1}\u200D\u{1F4BB}',
  '\u{1F47E}',
  '\u{1F916}',
  '\u{1F98A}',
  '\u{1F431}',
  '\u26A1',
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    final ordersCount =
        ref.watch(ordersProvider).valueOrNull?.length ?? 0;
    final favoritesCount =
        ref.watch(favoritesProvider).valueOrNull?.length ?? 0;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          const Text(
            'Profil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),

          // Profil kartasi
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradient
                    .map((c) => c.withOpacity(0.16))
                    .toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    user?.avatarEmoji ?? '\u{1F464}',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Mehmon',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDim,
                        ),
                      ),
                      if ((user?.address ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          user!.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditDialog(context, ref),
                  icon: const Icon(Icons.edit_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Statistika
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.receipt_long_rounded,
                  value: '$ordersCount',
                  label: 'Buyurtmalar',
                  onTap: () => context.go('/orders'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.favorite_rounded,
                  value: '$favoritesCount',
                  label: 'Sevimlilar',
                  onTap: () => context.push('/favorites'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Menyu
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            title: 'Buyurtmalarim',
            onTap: () => context.go('/orders'),
          ),
          _MenuTile(
            icon: Icons.favorite_rounded,
            title: 'Sevimlilar',
            onTap: () => context.push('/favorites'),
          ),
          _MenuTile(
            icon: Icons.build_circle_outlined,
            title: 'Kompyuter yig\u2018ish (PC Builder)',
            badge: 'Offline',
            onTap: () => context.push('/pc-builder'),
          ),
          _MenuTile(
            icon: Icons.auto_awesome_rounded,
            title: 'TEXNO AI yordamchi',
            onTap: () => context.push('/texno-ai'),
          ),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Sozlamalar',
            onTap: () => context.push('/settings'),
          ),
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.logout_rounded,
            title: 'Chiqish',
            danger: true,
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: TextStyle(fontSize: 11, color: AppColors.textDim),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(appStateProvider).currentUser;
    final nameController = TextEditingController(text: user?.name);
    final phoneController = TextEditingController(text: user?.phone);
    final addressController = TextEditingController(text: user?.address);
    var avatar = user?.avatarEmoji ?? '\u{1F464}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Profilni tahrirlash',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(avatar, style: const TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final e in _avatarEmojis)
                        GestureDetector(
                          onTap: () => setSheetState(() => avatar = e),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: avatar == e
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child:
                                Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Ism'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Telefon'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Manzil'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(appStateProvider).updateProfile(
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              address: addressController.text.trim(),
                              avatarEmoji: avatar,
                            );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: const Text('Saqlash'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Chiqish'),
        content: const Text(
            'Profildan chiqmoqchimisiz? Savat va buyurtmalar tarixi saqlanib qoladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(appStateProvider).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textDim),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
    this.badge,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: danger ? AppColors.danger : AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: danger ? AppColors.danger : AppColors.text,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: danger ? AppColors.danger : AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
