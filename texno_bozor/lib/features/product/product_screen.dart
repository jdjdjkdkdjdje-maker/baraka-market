import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/specs.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/database/app_database.dart';

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
    Future.microtask(() {
      ref.read(historyRepositoryProvider).addViewed(widget.productId);
    });
  }

  void _addToCart(Product product) {
    ref.read(cartRepositoryProvider).add(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Savatga qo\u2018shildi'),
        action: SnackBarAction(
          label: 'Savatga o\u2018tish',
          onPressed: () => context.go('/cart'),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productStream = ref
        .watch(productRepositoryProvider)
        .watchById(widget.productId);
    final reviews = ref
        .watch(reviewRepositoryProvider)
        .watchForProduct(widget.productId);
    final allProducts = ref.watch(productsProvider).valueOrNull ?? [];
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? {};

    return StreamBuilder<Product?>(
      stream: productStream,
      builder: (context, snapshot) {
        final product = snapshot.data;
        if (product == null) {
          return const Scaffold(body: LoadingView());
        }

        final isFavorite = favorites.contains(product.id);
        final discount = discountPercent(product.price, product.oldPrice);
        final specs = parseSpecs(product.specsJson)
            .entries
            .where((e) => !e.key.startsWith('pc_part'))
            .toList();
        final similar = allProducts
            .where((p) =>
                p.categoryId == product.categoryId && p.id != product.id)
            .take(8)
            .toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.card,
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color:
                          isFavorite ? AppColors.danger : AppColors.textDim,
                    ),
                    onPressed: () => ref
                        .read(favoritesRepositoryProvider)
                        .toggle(product.id),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductVisual(
                          product: product, height: 280, fontSize: 110),
                      if (discount > 0)
                        Positioned(
                          top: 100,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.gradientWarm),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '-$discount% chegirma',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          RatingStars(rating: product.rating, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '(${product.reviewsCount} ta sharh)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            product.stock > 0
                                ? Icons.check_circle_outline_rounded
                                : Icons.cancel_outlined,
                            size: 16,
                            color: product.stock > 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.stock > 0
                                ? 'Omborda: ${product.stock} ta'
                                : 'Omborda yo\u2018q',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.stock > 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Narx bloki
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.oldPrice != null)
                                    Text(
                                      formatSum(product.oldPrice!),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textDim,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                  PriceText(product.price, fontSize: 24),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      size: 14, color: AppColors.success),
                                  SizedBox(width: 5),
                                  Text(
                                    'Bepul yetkazish 5 mln dan',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sotuvchi va kafolat
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.storefront_outlined,
                              title: 'Sotuvchi',
                              value: AppConstants.sellerName,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.verified_user_outlined,
                              title: 'Kafolat',
                              value: product.warranty,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tugmalar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: GradientBox(
                          onTap: product.stock > 0
                              ? () {
                                  _addToCart(product);
                                  context.go('/cart');
                                }
                              : null,
                          child: const Center(
                            child: Text(
                              'Hozir xarid qilish',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: product.stock > 0
                              ? () => _addToCart(product)
                              : null,
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: const Text('Savatga qo\u2018shish'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tavsif
                      const Text(
                        'Tavsif',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isEmpty
                            ? 'Mahsulot haqida ma\u2018lumot.'
                            : product.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDim,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Texnik xususiyatlar
                      if (specs.isNotEmpty) ...[
                        const Text(
                          'Texnik xususiyatlar',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < specs.length; i++) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          specs[i].key,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textDim,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          specs[i].value,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < specs.length - 1)
                                  const Divider(
                                      height: 1, indent: 14, endIndent: 14),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],

                      // Sharhlar
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Sharhlar',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showReviewDialog(context, product),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Sharh qoldirish'),
                          ),
                        ],
                      ),
                      StreamBuilder<List<Review>>(
                        stream: reviews,
                        builder: (context, reviewSnapshot) {
                          final list = reviewSnapshot.data ?? [];
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'Hali sharhlar yo\u2018q. Birinchi bo\u2018lib sharh qoldiring!',
                                style: TextStyle(
                                    color: AppColors.textDim, fontSize: 13),
                              ),
                            );
                          }
                          return Column(
                            children: list
                                .map((r) => Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                        child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                r.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const Spacer(),
                                              RatingStars(
                                                  rating: r.rating, size: 12),
                                            ],
                                          ),
                                          if (r.reviewText.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              r.reviewText,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textDim,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            formatDateTime(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    r.createdAt)),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textDim,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // O'xshash mahsulotlar
                      if (similar.isNotEmpty) ...[
                        const Text(
                          'O\u2018xshash mahsulotlar',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 250,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) =>
                                ProductCard(product: similar[i], width: 168),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, Product product) {
    final textController = TextEditingController();
    var rating = 5.0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sharh qoldirish',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () =>
                              setSheetState(() => rating = i.toDouble()),
                          icon: Icon(
                            i <= rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.warning,
                            size: 32,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text('${rating.toStringAsFixed(0)} / 5'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Fikringizni yozing...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(appStateProvider).currentUser;
                        await ref.read(reviewRepositoryProvider).addReview(
                              id: const Uuid().v4(),
                              productId: product.id,
                              userName: user?.name ?? 'Anonim',
                              rating: rating,
                              text: textController.text.trim(),
                            );
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: const Text('Yuborish'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textDim),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
