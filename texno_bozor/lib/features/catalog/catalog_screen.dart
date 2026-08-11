import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/category_icons.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/models/app_models.dart';
import '../../data/models/enums.dart';

/// Katalog: kategoriyalar, filtr, saralash va mahsulotlar grid'i.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, this.initialCategoryId, this.initialBrand});

  final String? initialCategoryId;
  final String? initialBrand;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.initialCategoryId != null || widget.initialBrand != null) {
        final current = ref.read(catalogFilterProvider);
        ref.read(catalogFilterProvider.notifier).state = current.copyWith(
              categoryId: () => widget.initialCategoryId,
              brands: widget.initialBrand != null
                  ? {widget.initialBrand!}
                  : current.brands,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final filter = ref.watch(catalogFilterProvider);
    final filtered = ref.watch(filteredProductsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Katalog',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Qidiruv',
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),

          // Kategoriya chiplari
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'Barchasi',
                  selected: filter.categoryId == null,
                  onTap: () => ref
                      .read(catalogFilterProvider.notifier)
                      .state = filter.copyWith(categoryId: () => null),
                ),
                ...categories.map(
                  (c) => _CategoryChip(
                    label: c.name,
                    icon: iconForCategory(c.icon),
                    selected: filter.categoryId == c.id,
                    onTap: () =>
                        ref.read(catalogFilterProvider.notifier).state =
                            filter.copyWith(
                              categoryId: () =>
                                  filter.categoryId == c.id ? null : c.id,
                            ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Saralash va filtr tugmalari
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSortSheet(context, ref, filter),
                    icon: const Icon(Icons.sort_rounded, size: 18),
                    label: Flexible(
                      child: Text(
                        filter.sort.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _showFilterSheet(context, ref, filter),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune_rounded, size: 18),
                      if (filter.activeFilterCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${filter.activeFilterCount}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF04222B),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('Filtr'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Natijalar
          Expanded(
            child: filtered.when(
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Hech narsa topilmadi',
                    subtitle:
                        'Filtr shartlarini o\u2018zgartirib qayta urinib ko\u2018ring',
                    actionLabel: 'Filtrlarni tozalash',
                    onAction: () => ref
                        .read(catalogFilterProvider.notifier)
                        .state = const ProductFilter(),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      ProductCard(product: products[i]),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Xatolik yuz berdi',
                subtitle: '$e',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(
      BuildContext context, WidgetRef ref, ProductFilter filter) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Saralash',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              ...ProductSort.values.map(
                (s) => ListTile(
                  leading: Icon(
                    filter.sort == s
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: filter.sort == s
                        ? AppColors.primary
                        : AppColors.textDim,
                  ),
                  title: Text(s.label),
                  onTap: () {
                    ref.read(catalogFilterProvider.notifier).state =
                        filter.copyWith(sort: s);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(
      BuildContext context, WidgetRef ref, ProductFilter filter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FilterSheet(initialFilter: filter),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15,
                  color: selected ? AppColors.primary : AppColors.textDim),
              const SizedBox(width: 5),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Filtrlash paneli: narx oralig'i, brend, reyting.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, required this.initialFilter});

  final ProductFilter initialFilter;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late double _minValue;
  late double _maxValue;
  double _rangeStart = 0;
  double _rangeEnd = 0;
  late Set<String> _brands;
  late double _minRating;
  List<String> _allBrands = [];
  bool _brandsLoaded = false;

  @override
  void initState() {
    super.initState();
    _brands = {...widget.initialFilter.brands};
    _minRating = widget.initialFilter.minRating;
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final products = await ref.read(productRepositoryProvider).getAll();
    if (!mounted) return;
    final prices = products.map((p) => p.price).toList();
    _minValue = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b).toDouble();
    _maxValue = prices.isEmpty ? 1 : prices.reduce((a, b) => a > b ? a : b).toDouble();
    _rangeStart = widget.initialFilter.minPrice?.toDouble() ?? _minValue;
    _rangeEnd = widget.initialFilter.maxPrice?.toDouble() ?? _maxValue;
    _allBrands = products.map((p) => p.brand).toSet().toList()..sort();
    _brandsLoaded = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _brandsLoaded
              ? ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Filtrlash',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    const Text('Narx oralig\u2018i',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    RangeSlider(
                      values: RangeValues(_rangeStart, _rangeEnd),
                      min: _minValue,
                      max: _maxValue,
                      divisions: 60,
                      activeColor: AppColors.primary,
                      labels: RangeLabels(
                        formatNumber(_rangeStart.round()),
                        formatNumber(_rangeEnd.round()),
                      ),
                      onChanged: (v) =>
                          setState(() => (_rangeStart, _rangeEnd) = (v.start, v.end)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatSum(_rangeStart.round()),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textDim)),
                        Text(formatSum(_rangeEnd.round()),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textDim)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Reyting',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final r in const [0.0, 3.0, 4.0, 4.5])
                          ChoiceChip(
                            label: Text(
                                r == 0 ? 'Barchasi' : '$r+ \u2605'),
                            selected: _minRating == r,
                            onSelected: (_) => setState(() => _minRating = r),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Brendlar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final brand in _allBrands)
                          FilterChip(
                            label: Text(brand),
                            selected: _brands.contains(brand),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _brands.add(brand);
                                } else {
                                  _brands.remove(brand);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(catalogFilterProvider.notifier).state =
                                  widget.initialFilter.copyWith(
                                brands: {},
                                minPrice: () => null,
                                maxPrice: () => null,
                                minRating: 0,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Tozalash'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(catalogFilterProvider.notifier).state =
                                  widget.initialFilter.copyWith(
                                brands: _brands,
                                minPrice: () => _rangeStart > _minValue
                                    ? _rangeStart.round()
                                    : null,
                                maxPrice: () => _rangeEnd < _maxValue
                                    ? _rangeEnd.round()
                                    : null,
                                minRating: _minRating,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Qo\u2018llash'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
