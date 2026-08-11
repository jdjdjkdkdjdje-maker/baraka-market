import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/product_card.dart';

/// QIDIRUV — lokal, internetsiz ishlaydi.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  static const List<String> _popularQueries = [
    'RTX 4060',
    'iPhone 15',
    'noutbuk',
    'quloqchin',
    'SSD 1TB',
    'gaming klaviatura',
    'monitor 144Hz',
    'powerbank',
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  Future<void> _submit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    _controller.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
    await ref.read(historyRepositoryProvider).addSearch(query);
    ref.invalidate(recentSearchesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final recent = ref.watch(recentSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Mahsulot, brend yoki model...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    ),
            ),
          ),
        ),
      ),
      body: query.trim().isEmpty
          ? _suggestions(recent)
          : results.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: '$e'),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Hech narsa topilmadi',
                    message: 'Boshqa so\u2018z bilan qidirib ko\u2018ring',
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${items.length} ta natija',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => ProductListTile(
                          product: items[index],
                          onTap: () {
                            _submit(_controller.text);
                            Navigator.of(context)
                                .pushNamed('/product', arguments: items[index].id);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _suggestions(AsyncValue<List<String>> recent) {
    final history = recent.value ?? const <String>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Oxirgi qidiruvlar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(historyRepositoryProvider).clearSearches();
                  ref.invalidate(recentSearchesProvider);
                },
                child: const Text('Tozalash'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final item in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history_rounded,
                  size: 20, color: AppColors.textMuted),
              title: Text(item, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.north_west_rounded,
                  size: 16, color: AppColors.textMuted),
              onTap: () {
                _controller.text = item;
                _submit(item);
              },
            ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Ommabop so\u2018rovlar',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _popularQueries)
              ActionChip(
                label: Text(q),
                backgroundColor: AppColors.surface,
                onPressed: () {
                  _controller.text = q;
                  _submit(q);
                },
              ),
          ],
        ),
      ],
    );
  }
}
