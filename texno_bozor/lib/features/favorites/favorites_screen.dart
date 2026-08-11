import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/ui_widgets.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sevimlilar')),
      body: favorites.when(
        data: (products) {
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline_rounded,
              title: 'Sevimlilar bo\u2018sh',
              subtitle:
                  'Mahsulot kartasidagi yurakcha belgisini bosib sevimlilarga qo\u2018shing',
              actionLabel: 'Katalogga o\u2018tish',
              onAction: () => context.go('/catalog'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemCount: products.length,
            itemBuilder: (context, i) => ProductCard(product: products[i]),
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('Xato: $e')),
      ),
    );
  }
}
