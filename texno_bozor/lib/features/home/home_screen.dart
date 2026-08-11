import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/models.dart';

/// BOSH SAHIFA — bannerlar, kategoriyalar, tavsiyalar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  static const List<({String image, String title, String subtitle})> _banners = [
    (
      image: 'assets/banners/banner_1.jpg',
      title: 'Texnika bozori cho\u2018ntagingizda',
      subtitle: 'Minglab mahsulot, bitta ilovada',
    ),
    (
      image: 'assets/banners/banner_2.jpg',
      title: 'Gaming komplektlar',
      subtitle: 'Videokarta va protsessorlarga chegirma',
    ),
    (
      image: 'assets/banners/banner_3.jpg',
      title: 'Smartfon va soatlar',
      subtitle: 'Yangi modellar keldi',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % _banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(popularProductsProvider);
    ref.invalidate(newProductsProvider);
    ref.invalidate(discountedProductsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(recentlyViewedProvider);
    await ref.read(cartProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final popular = ref.watch(popularProductsProvider);
    final discounted = ref.watch(discountedProductsProvider);
    final newest = ref.watch(newProductsProvider);
    final viewed = ref.watch(recentlyViewedProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(child: _bannerCarousel()),
              SliverToBoxAdapter(child: _aiCard(context)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Kategoriyalar',
                  actionLabel: 'Barchasi',
                  onAction: () => Navigator.of(context).pushNamed('/catalog'),
                ),
              ),
              SliverToBoxAdapter(child: _categories(categories)),
              if (discounted.value?.isNotEmpty ?? false) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Chegirmalar',
                    subtitle: 'Cheklangan miqdorda',
                    actionLabel: 'Barchasi',
                    onAction: () {
                      ref.read(catalogFilterProvider.notifier).state =
                          const ProductFilter(
                        onlyDiscount: true,
                        sort: SortOption.discount,
                      );
                      Navigator.of(context).pushNamed('/catalog');
                    },
                  ),
                ),
                SliverToBoxAdapter(child: _horizontalList(discounted)),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Ommabop mahsulotlar',
                  actionLabel: 'Barchasi',
                  onAction: () {
                    ref.read(catalogFilterProvider.notifier).state =
                        const ProductFilter(sort: SortOption.popular);
                    Navigator.of(context).pushNamed('/catalog');
                  },
                ),
              ),
              SliverToBoxAdapter(child: _horizontalList(popular)),
              SliverToBoxAdapter(child: _pcBuilderCard(context)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Yangi kelganlar',
                  actionLabel: 'Barchasi',
                  onAction: () {
                    ref.read(catalogFilterProvider.notifier).state =
                        const ProductFilter(sort: SortOption.newest);
                    Navigator.of(context).pushNamed('/catalog');
                  },
                ),
              ),
              SliverToBoxAdapter(child: _horizontalList(newest)),
              if (viewed.value?.isNotEmpty ?? false) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(title: 'Yaqinda ko\u2018rilganlar'),
                ),
                SliverToBoxAdapter(child: _horizontalList(viewed)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEXNO BOZOR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Elektronika marketplace',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _bannerIndex = index),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(source: banner.image, radius: 0),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.black.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 210,
                              child: Text(
                                banner.title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  height: 1.2,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 200,
                              child: Text(
                                banner.subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFD8DEE6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _bannerIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _bannerIndex
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _aiCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/ai'),
          child: Ink(
            decoration: const BoxDecoration(gradient: AppColors.aiGradient),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEXNO AI yordamchi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Byudjetingizni ayting — mos texnikani topib beraman',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFE8EEF7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pcBuilderCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/pc-builder'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.memory_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kompyuter yig\u2018ish',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Qismlarni tanlang — moslikni o\u2018zimiz tekshiramiz',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categories(AsyncValue<List<Category>> categories) {
    return categories.when(
      loading: () => const SizedBox(height: 108, child: LoadingState()),
      error: (e, _) => SizedBox(
        height: 108,
        child: ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
      ),
      data: (items) => SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final category = items[index];
            return SizedBox(
              width: 84,
              child: Column(
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref.read(catalogFilterProvider.notifier).state =
                            ProductFilter(categoryId: category.id);
                        Navigator.of(context).pushNamed('/catalog');
                      },
                      child: SizedBox(
                        width: 84,
                        height: 74,
                        child: AppImage(source: category.image, radius: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _horizontalList(AsyncValue<List<Product>> products) {
    return products.when(
      loading: () => const SizedBox(height: 280, child: LoadingState()),
      error: (e, _) => SizedBox(height: 280, child: ErrorState(message: '$e')),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Mahsulot topilmadi',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        return SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                ProductCard(product: items[index], width: 165),
          ),
        );
      },
    );
  }
}
