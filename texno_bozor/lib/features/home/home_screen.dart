import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/category_icons.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/models/app_models.dart';

const List<BannerData> _banners = [
  BannerData(
    title: 'RTX 5070 sotuvda!',
    subtitle: 'Yangi avlod videokartalarini birinchi bo\u2018lib xarid qiling',
    emoji: '\u{1F3AE}',
    route: '/catalog?cat=cat_gpu',
    gradientIndex: 0,
  ),
  BannerData(
    title: 'Kompyuterni o\u2018zingiz yig\u2018ing',
    subtitle: 'PC Builder komponentlar mosligini avtomatik tekshiradi',
    emoji: '\u{1F5A5}\uFE0F',
    route: '/pc-builder',
    gradientIndex: 1,
  ),
  BannerData(
    title: 'TEXNO AI yordamchi',
    subtitle: 'Texnika tanlashda sun\u2018iy intellektdan maslahat oling',
    emoji: '\u{1F916}',
    route: '/texno-ai',
    gradientIndex: 2,
  ),
  BannerData(
    title: '5 mln so\u2018mdan yuqori xaridlar',
    subtitle: 'Yetkazib berish butunlay BEPUL',
    emoji: '\u{1F69A}',
    route: '/catalog',
    gradientIndex: 3,
  ),
];

const List<List<Color>> _bannerGradients = [
  [Color(0xFF0E7490), Color(0xFF4F46E5)],
  [Color(0xFF7C3AED), Color(0xFFDB2777)],
  [Color(0xFF059669), Color(0xFF0EA5E9)],
  [Color(0xFFD97706), Color(0xFFDC2626)],
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ----- Logo + AI tugmasi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Expanded(child: LogoTitle(showTagline: true)),
                GradientBox(
                  borderRadius: 14,
                  onTap: () => context.push('/texno-ai'),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'TEXNO AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ----- Qidiruv
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: AppColors.textDim, size: 21),
                      SizedBox(width: 10),
                      Text(
                        'Mahsulot qidirish... (masalan: RTX 5070)',
                        style:
                            TextStyle(color: AppColors.textDim, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ----- Bannerlar
          const _BannerCarousel(),

          // ----- Kategoriyalar
          SectionHeader(
            title: 'Kategoriyalar',
            onSeeAll: () => context.go('/catalog'),
          ),
          categories.maybeWhen(
            data: (cats) => SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  return _CategoryTile(
                    name: cat.name,
                    icon: iconForCategory(cat.icon),
                    onTap: () => context.go('/catalog?cat=${cat.id}'),
                  );
                },
              ),
            ),
            orElse: () => const SizedBox(height: 96, child: LoadingView()),
          ),

          // ----- Mahsulot bo'limlari
          products.maybeWhen(
            data: (all) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(context, 'Chegirmadagi mahsulotlar',
                    all.where((p) => p.oldPrice != null).toList()),
                _section(
                  context,
                  'Mashhur mahsulotlar',
                  [...all]..sort((a, b) => b.popularity.compareTo(a.popularity)),
                ),
                _section(
                  context,
                  'Eng ko\u2018p sotilganlar',
                  all.where((p) => p.isTop == 1).toList(),
                ),
                _section(
                  context,
                  'Yangi mahsulotlar',
                  [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                ),
                _section(
                  context,
                  'Tavsiya etilganlar',
                  [...all]..sort((a, b) => b.rating.compareTo(a.rating)),
                ),
                _brandsSection(context, all),
              ],
            ),
            orElse: () => const Padding(
              padding: EdgeInsets.all(40),
              child: LoadingView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Product> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeAll: () => context.go('/catalog'),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.take(10).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ProductCard(
              product: items.take(10).toList()[i],
              width: 168,
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandsSection(BuildContext context, List<Product> all) {
    final brands = all.map((p) => p.brand).toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mashhur brendlar'),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final brand = brands[i];
              final count =
                  all.where((p) => p.brand == brand).length;
              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.go(
                    '/catalog?brand=${Uri.encodeComponent(brand)}',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          brand,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count ta mahsulot',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final IconData icon;
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
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradient
                        .map((c) => c.withOpacity(0.16))
                        .toList(),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: AppColors.primary),
              ),
              const SizedBox(height: 7),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10.5, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.isEmpty) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) {
              final banner = _banners[i];
              final gradient =
                  _bannerGradients[banner.gradientIndex % _bannerGradients.length];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Material(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.go(banner.route),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  banner.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(banner.emoji,
                              style: const TextStyle(fontSize: 46)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
