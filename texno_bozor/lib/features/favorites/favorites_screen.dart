import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/product_card.dart';

/// SEVIMLILAR — lokal saqlanadi.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sevimlilar'),
        actions: [
          if (products.value?.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Ro\u2018yxatni tozalash',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sevimlilarni tozalash'),
                    content: const Text(
                        'Barcha mahsulotlar ro\u2018yxatdan olib tashlansinmi?'),
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
                  await ref.read(favoritesProvider.notifier).clear();
                  if (context.mounted) {
                    showAppSnack(context, 'Sevimlilar tozalandi');
                  }
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: products.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Sevimlilar bo\u2018sh',
              message: 'Yoqqan mahsulotlarni ❤️ belgisi bilan saqlang',
              actionLabel: 'Katalogga o\u2018tish',
              onAction: () => Navigator.of(context).pushNamed('/catalog'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 292,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                ProductCard(product: items[index]),
          );
        },
      ),
    );
  }
}
