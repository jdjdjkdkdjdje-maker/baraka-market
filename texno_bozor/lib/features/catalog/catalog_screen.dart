import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/models.dart';
import 'filter_sheet.dart';

/// KATALOG — kategoriyalar, filtr va saralash.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    final products = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () => _openSort(context, ref),
            icon: const Icon(Icons.swap_vert_rounded),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => showFilterSheet(context, ref),
                icon: const Icon(Icons.tune_rounded),
              ),
              if (filter.activeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${filter.activeCount}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _categoryChips(context, ref, categories, filter),
          _activeFilters(context, ref, filter),
          Expanded(
            child: products.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(filteredProductsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Mahsulot topilmadi',
                    message: 'Filtrlarni o\u2018zgartirib ko\u2018ring',
                    actionLabel: filter.hasActiveFilters
                        ? 'Filtrlarni tozalash'
                        : null,
                    onAction: filter.hasActiveFilters
                        ? () => ref
                            .read(catalogFilterProvider.notifier)
                            .state = filter.cleared()
                        : null,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
          ),
        ],
      ),
    );
  }

  Widget _categoryChips(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Category>> categories,
    ProductFilter filter,
  ) {
    return categories.maybeWhen(
      data: (items) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _chip(
                label: 'Hammasi',
                selected: filter.categoryId == null,
                onTap: () => ref.read(catalogFilterProvider.notifier).state =
                    filter.copyWith(clearCategory: true, brands: const {}),
              );
            }
            final category = items[index - 1];
            return _chip(
              label: category.name,
              selected: filter.categoryId == category.id,
              onTap: () => ref.read(catalogFilterProvider.notifier).state =
                  filter.copyWith(categoryId: category.id, brands: const {}),
            );
          },
        ),
      ),
      orElse: () => const SizedBox(height: 46),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeFilters(
      BuildContext context, WidgetRef ref, ProductFilter filter) {
    if (!filter.hasActiveFilters) return const SizedBox.shrink();

    final chips = <Widget>[];
    void addChip(String label, VoidCallback onRemove) {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close_rounded, size: 15),
          onDeleted: onRemove,
          backgroundColor: AppColors.surfaceHigh,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ));
    }

    final notifier = ref.read(catalogFilterProvider.notifier);
    for (final brand in filter.brands) {
      addChip(brand, () {
        final brands = {...filter.brands}..remove(brand);
        notifier.state = filter.copyWith(brands: brands);
      });
    }
    if (filter.minPrice != null || filter.maxPrice != null) {
      final from = filter.minPrice == null
          ? ''
          : 'dan ${Format.shortPrice(filter.minPrice!)}';
      final to = filter.maxPrice == null
          ? ''
          : 'gacha ${Format.shortPrice(filter.maxPrice!)}';
      addChip('Narx $from $to'.trim(),
          () => notifier.state = filter.copyWith(clearPrice: true));
    }
    if (filter.minRating > 0) {
      addChip('Reyting ${filter.minRating}+',
          () => notifier.state = filter.copyWith(minRating: 0));
    }
    if (filter.onlyInStock) {
      addChip('Omborda bor',
          () => notifier.state = filter.copyWith(onlyInStock: false));
    }
    if (filter.onlyDiscount) {
      addChip('Chegirmada',
          () => notifier.state = filter.copyWith(onlyDiscount: false));
    }

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...chips,
          TextButton(
            onPressed: () => notifier.state = filter.cleared(),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
  }

  void _openSort(BuildContext context, WidgetRef ref) {
    final filter = ref.read(catalogFilterProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Saralash',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final option in SortOption.values)
              ListTile(
                title: Text(option.label),
                trailing: filter.sort == option
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(catalogFilterProvider.notifier).state =
                      filter.copyWith(sort: option);
                  Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
