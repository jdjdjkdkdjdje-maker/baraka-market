import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'app_widgets.dart';

/// Mahsulot kartochkasi — katalog, bosh sahifa va qidiruvda ishlatiladi.
class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.onTap,
  });

  final Product product;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).value ?? const <String>[];
    final isFavorite = favorites.contains(product.id);
    final cart = ref.watch(cartProvider).value;
    final inCart = (cart?.quantityOf(product.id) ?? 0) > 0;

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ??
              () => Navigator.of(context)
                  .pushNamed('/product', arguments: product.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: AppImage(source: product.image, radius: 0),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: AppBadge(
                        text: '-${product.discountPercent}%',
                        color: AppColors.danger,
                      ),
                    )
                  else if (product.isNew)
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: AppBadge(text: 'Yangi', color: AppColors.accent),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: _FavoriteButton(
                      productId: product.id,
                      isFavorite: isFavorite,
                    ),
                  ),
                  if (!product.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: const Text(
                          'Omborda yo\u2018q',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RatingStars(
                      rating: product.rating,
                      count: product.ratingCount,
                      size: 12,
                    ),
                    const SizedBox(height: 8),
                    if (product.hasDiscount)
                      Text(
                        Format.price(product.oldPrice),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            Format.price(product.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        _CartButton(product: product, inCart: inCart),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId, required this.isFavorite});

  final String productId;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final added =
              await ref.read(favoritesProvider.notifier).toggle(productId);
          if (context.mounted) {
            showAppSnack(
              context,
              added ? 'Sevimlilarga qo\u2018shildi' : 'Sevimlilardan olindi',
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 19,
            color: isFavorite ? AppColors.danger : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CartButton extends ConsumerWidget {
  const _CartButton({required this.product, required this.inCart});

  final Product product;
  final bool inCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = product.inStock;
    return Material(
      color: !enabled
          ? AppColors.surfaceHigh
          : inCart
              ? AppColors.success
              : AppColors.primary,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: !enabled
            ? null
            : () async {
                await ref.read(cartProvider.notifier).add(product.id);
                if (context.mounted) {
                  showAppSnack(context, 'Savatga qo\u2018shildi');
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            inCart
                ? Icons.check_rounded
                : Icons.add_shopping_cart_rounded,
            size: 18,
            color: enabled ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Ro'yxat ko'rinishidagi gorizontal mahsulot kartochkasi.
class ProductListTile extends ConsumerWidget {
  const ProductListTile({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ??
            () => Navigator.of(context)
                .pushNamed('/product', arguments: product.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: AppImage(source: product.image),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RatingStars(
                      rating: product.rating,
                      count: product.ratingCount,
                      size: 12,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          Format.price(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            Format.price(product.oldPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
