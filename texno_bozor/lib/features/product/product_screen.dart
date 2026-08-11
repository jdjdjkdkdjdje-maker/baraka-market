import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/models.dart';

/// MAHSULOT sahifasi — rasm, narx, xususiyatlar, sharhlar, o'xshashlar.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  @override
  void initState() {
    super.initState();
    // Ko'rilganlar tarixiga yozamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(historyRepositoryProvider).addViewed(widget.productId);
      if (mounted) ref.invalidate(recentlyViewedProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
        data: (product) {
          if (product == null) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Mahsulot topilmadi',
            );
          }
          return _content(product);
        },
      ),
      bottomNavigationBar: productAsync.value == null
          ? null
          : _bottomBar(productAsync.value!),
    );
  }

  Widget _content(Product product) {
    final favorites = ref.watch(favoritesProvider).value ?? const <String>[];
    final isFavorite = favorites.contains(product.id);
    final reviews = ref.watch(productReviewsProvider(product.id));
    final similar = ref.watch(similarProductsProvider(product));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(Icons.arrow_back_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final added = await ref
                    .read(favoritesProvider.notifier)
                    .toggle(product.id);
                if (mounted) {
                  showAppSnack(
                    context,
                    added
                        ? 'Sevimlilarga qo\u2018shildi'
                        : 'Sevimlilardan olindi',
                  );
                }
              },
              icon: CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorite ? AppColors.danger : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(source: product.image, radius: 0),
                if (product.hasDiscount)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: AppBadge(
                      text: '-${product.discountPercent}% chegirma',
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    RatingStars(
                      rating: product.rating,
                      count: product.ratingCount,
                      size: 14,
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      product.inStock
                          ? Icons.check_circle_rounded
                          : Icons.remove_circle_outline_rounded,
                      size: 15,
                      color: product.inStock
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.inStock
                          ? 'Omborda ${product.stock} dona'
                          : 'Omborda yo\u2018q',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: product.inStock
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Format.price(product.price),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          Format.price(product.oldPrice),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tejaysiz: '
                      '${Format.price(product.oldPrice - product.price)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _infoRow(),
                const SizedBox(height: 20),
                if (product.description.isNotEmpty) ...[
                  const Text(
                    'Tavsif',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (product.specs.isNotEmpty) ...[
                  const Text(
                    'Xususiyatlar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _specsTable(product),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _reviewsSection(product, reviews)),
        SliverToBoxAdapter(
          child: similar.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'O\u2018xshash mahsulotlar'),
                      SizedBox(
                        height: 292,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => ProductCard(
                            product: items[index],
                            width: 165,
                            onTap: () => Navigator.of(context).pushReplacementNamed(
                              '/product',
                              arguments: items[index].id,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _infoRow() {
    const items = [
      (Icons.local_shipping_outlined, 'Tez yetkazish', '1-2 kun'),
      (Icons.verified_user_outlined, 'Kafolat', '12 oy'),
      (Icons.autorenew_rounded, 'Qaytarish', '14 kun'),
    ];
    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(item.$1, size: 20, color: AppColors.accent),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    item.$3,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _specsTable(Product product) {
    final entries = product.specs.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: i == entries.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _humanize(entries[i].key),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entries[i].value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _humanize(String key) {
    const names = {
      'socket': 'Soket',
      'yadro': 'Yadrolar',
      'oqim': 'Oqimlar',
      'chastota': 'Chastota',
      'tdp': 'TDP (W)',
      'xotira': 'Xotira',
      'grafika': 'Integratsiyalangan grafika',
      'interfeys': 'Interfeys',
      'uzunlik': 'Uzunlik (mm)',
      'quvvat': 'Quvvat (W)',
      'chiqish': 'Chiqishlar',
      'chipset': 'Chipset',
      'form': 'Format',
      'slot': 'Slotlar',
      'm2': 'M.2 slotlar',
      'hajm': 'Hajm',
      'modul': 'Modullar',
      'kechikish': 'Kechikish',
      'tezlik': 'Tezlik',
      'chidamlilik': 'Chidamlilik',
      'aylanish': 'Aylanish tezligi',
      'kesh': 'Kesh',
      'sertifikat': 'Sertifikat',
      'gpu_uzunlik': 'Videokarta uchun joy (mm)',
      'kuler_balandlik': 'Sovutgich balandligi (mm)',
      'psu_uzunlik': 'Quvvat bloki uchun joy (mm)',
      'fan': 'Ventilyatorlar',
      'tip': 'Turi',
      'balandlik': 'Balandlik (mm)',
      'ekran': 'Ekran',
      'protsessor': 'Protsessor',
      'disk': 'Xotira',
      'batareya': 'Batareya',
      'og\u2018irlik': 'Og\u2018irligi',
      'video': 'Videokarta',
      'kamera': 'Kamera',
      'diagonal': 'Diagonal',
      'ruxsat': 'Ruxsat',
      'matritsa': 'Matritsa',
      'javob': 'Javob vaqti',
      'shovqin': 'Shovqin bostirish',
      'ulanish': 'Ulanish',
      'sensor': 'Sensor',
      'suv': 'Suvdan himoya',
      'standart': 'Standart',
      'port': 'Portlar',
      'antenna': 'Antennalar',
      'sig\u2018im': 'Sig\u2018imi',
      'tez': 'Tez quvvatlash',
      'material': 'Material',
      'platforma': 'Platforma',
      'smart': 'Smart tizim',
      'rang': 'Rang',
      'yoritish': 'Yoritish',
      'switch': 'Switch',
      'tugma': 'Tugmalar',
    };
    final name = names[key];
    if (name != null) return name;
    return key[0].toUpperCase() + key.substring(1);
  }

  Widget _reviewsSection(Product product, AsyncValue<List<Review>> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Sharhlar',
          subtitle: '${product.ratingCount} ta baho',
          actionLabel: 'Sharh yozish',
          onAction: () => _writeReview(product),
        ),
        reviews.maybeWhen(
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Hozircha sharhlar yo\u2018q. Birinchi bo\u2018lib fikr '
                  'bildiring!',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }
            return Column(
              children: [
                for (final review in items.take(4))
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.surfaceHigh,
                              child: Text(
                                review.author.isEmpty
                                    ? '?'
                                    : review.author[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.author,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    Format.relative(review.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Icon(
                                    i < review.rating
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 14,
                                    color: AppColors.warning,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (review.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            review.text,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _writeReview(Product product) async {
    final controller = TextEditingController();
    var rating = 5;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sharh yozish',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setSheetState(() => rating = i),
                        icon: Icon(
                          i <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 32,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Mahsulot haqida fikringiz...',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yuborish'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final user = ref.read(userProvider).value;
    await ref.read(reviewRepositoryProvider).add(Review(
          id: 'rev-local-${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          author: (user?.name.trim().isNotEmpty ?? false)
              ? user!.name
              : 'Mehmon',
          rating: rating,
          text: controller.text.trim(),
          createdAt: DateTime.now(),
        ));
    if (!mounted) return;
    ref.invalidate(productReviewsProvider(product.id));
    showAppSnack(context, 'Sharhingiz saqlandi. Rahmat!');
  }

  Widget _bottomBar(Product product) {
    final cart = ref.watch(cartProvider).value;
    final quantity = cart?.quantityOf(product.id) ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (quantity > 0) ...[
              QuantityStepper(
                quantity: quantity,
                onIncrement: () =>
                    ref.read(cartProvider.notifier).increment(product.id),
                onDecrement: () =>
                    ref.read(cartProvider.notifier).decrement(product.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/cart'),
                  child: const Text('Savatga o\u2018tish'),
                ),
              ),
            ] else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !product.inStock
                      ? null
                      : () async {
                          await ref
                              .read(cartProvider.notifier)
                              .add(product.id);
                          if (mounted) {
                            showAppSnack(context, 'Savatga qo\u2018shildi');
                          }
                        },
                  icon: const Icon(Icons.shopping_cart_rounded, size: 20),
                  label: Text(
                    product.inStock
                        ? 'Savatga qo\u2018shish'
                        : 'Omborda yo\u2018q',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
