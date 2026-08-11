import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/models.dart';

/// Katalog filtri — narx, brend, reyting, ombor.
Future<void> showFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(catalogFilterProvider);
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider(_draft.categoryId));
    final range = ref.watch(priceRangeProvider(_draft.categoryId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filtrlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _title('Narx oralig\u2018i'),
                range.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (bounds) => _priceSlider(bounds.$1, bounds.$2),
                ),
                const SizedBox(height: 20),
                _title('Brend'),
                brands.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (items) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final brand in items)
                        FilterChip(
                          label: Text(brand),
                          selected: _draft.brands.contains(brand),
                          onSelected: (selected) {
                            setState(() {
                              final next = {..._draft.brands};
                              selected ? next.add(brand) : next.remove(brand);
                              _draft = _draft.copyWith(brands: next);
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _title('Minimal reyting'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in [0.0, 4.0, 4.5, 4.8])
                      ChoiceChip(
                        label: Text(value == 0 ? 'Barchasi' : '$value+'),
                        selected: _draft.minRating == value,
                        onSelected: (_) => setState(
                            () => _draft = _draft.copyWith(minRating: value)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _draft.onlyInStock,
                  onChanged: (value) => setState(
                      () => _draft = _draft.copyWith(onlyInStock: value)),
                  title: const Text('Faqat omborda borlari'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _draft.onlyDiscount,
                  onChanged: (value) => setState(
                      () => _draft = _draft.copyWith(onlyDiscount: value)),
                  title: const Text('Faqat chegirmadagilar'),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _draft = _draft.cleared()),
                      child: const Text('Tozalash'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(catalogFilterProvider.notifier).state = _draft;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Qo\u2018llash'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );

  Widget _priceSlider(int min, int max) {
    if (max <= min) return const Text('Ma\u2018lumot yo\u2018q');

    final start = (_draft.minPrice ?? min).toDouble().clamp(
          min.toDouble(),
          max.toDouble(),
        );
    final end = (_draft.maxPrice ?? max).toDouble().clamp(
          min.toDouble(),
          max.toDouble(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: RangeValues(start, end),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: 40,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          labels: RangeLabels(
            Format.shortPrice(start),
            Format.shortPrice(end),
          ),
          onChanged: (values) => setState(() {
            _draft = _draft.copyWith(
              minPrice: values.start.round(),
              maxPrice: values.end.round(),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Format.price(start),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              Format.price(end),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
