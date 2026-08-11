import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/database/app_database.dart';

/// Lokal qidiruv: internet talab qilmaydi.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Product>? _results;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _results = null);
      return;
    }
    if (mounted) setState(() => _searching = true);
    final results = await ref.read(productRepositoryProvider).search(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
    await ref.read(historyRepositoryProvider).addSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryProvider).valueOrNull ?? [];
    final recentlyViewed =
        ref.watch(recentlyViewedProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: (v) => _search(v),
          decoration: InputDecoration(
            hintText: 'Mahsulot, brend, model...',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _results = null);
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: _results == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (history.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Qidiruv tarixi',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(historyRepositoryProvider)
                            .clearSearchHistory(),
                        child: const Text('Tozalash'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history
                        .map(
                          (h) => ActionChip(
                            avatar: const Icon(Icons.history_rounded,
                                size: 15),
                            label: Text(h.query),
                            onPressed: () {
                              _controller.text = h.query;
                              _search(h.query);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                if (recentlyViewed.isNotEmpty) ...[
                  const Text(
                    'Yaqinda ko\u2018rilganlar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyViewed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          ProductCard(product: recentlyViewed[i], width: 165),
                    ),
                  ),
                ],
                if (history.isEmpty && recentlyViewed.isEmpty)
                  const EmptyState(
                    icon: Icons.manage_search_rounded,
                    title: 'Qidiruvni boshlang',
                    subtitle:
                        'Mahsulot nomi, brend yoki model bo\u2018yicha qidiring. Masalan: RTX 5070, Samsung, iPhone',
                  ),
              ],
            )
          : _searching
              ? const LoadingView()
              : _results!.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Hech narsa topilmadi',
                      subtitle:
                          'Sorovni tekshirib qayta urinib ko\u2018ring yoki boshqa nom bilan qidiring',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${_results!.length} ta mahsulot topildi',
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                            itemCount: _results!.length,
                            itemBuilder: (context, i) =>
                                ProductCard(product: _results![i]),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
