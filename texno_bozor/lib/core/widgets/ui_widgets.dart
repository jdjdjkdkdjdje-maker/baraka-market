import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../constants/app_constants.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// TEXNO BOZOR logotipi: gradient kvadrat + chaqmoq.
class GradientLogo extends StatelessWidget {
  const GradientLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.bolt_rounded,
        color: Colors.white,
        size: size * 0.62,
      ),
    );
  }
}

/// "TEXNO BOZOR" sarlavhali logo bloki.
class LogoTitle extends StatelessWidget {
  const LogoTitle({super.key, this.logoSize = 40, this.showTagline = false});

  final double logoSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GradientLogo(size: logoSize),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.gradient,
              ).createShader(bounds),
              child: const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white,
                ),
              ),
            ),
            if (showTagline)
              const Text(
                AppConstants.appTagline,
                style: TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
          ],
        ),
      ],
    );
  }
}

/// Bo'lim sarlavhasi: nom + "Barchasi" tugmasi.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Barchasi'),
            ),
        ],
      ),
    );
  }
}

/// Narx matni.
class PriceText extends StatelessWidget {
  const PriceText(
    this.price, {
    super.key,
    this.fontSize = 16,
    this.bold = true,
    this.color = AppColors.text,
  });

  final int price;
  final double fontSize;
  final bool bold;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatSum(price),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        color: color,
      ),
    );
  }
}

/// Reyting yulduzlari.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 14});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 1,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// Mahsulot rasmi o'rniga: gradient + emoji. Rasmlar uchun keyinchalik
/// cached_network_image ishlatiladi (imageUrl bo'lsa).
class ProductVisual extends StatelessWidget {
  const ProductVisual({
    super.key,
    required this.product,
    this.height = 130,
    this.fontSize = 52,
  });

  final Product product;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardLight.withOpacity(0.9),
            AppColors.card.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        product.emoji,
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}

/// Mahsulot kartasi (grid va gorizontal ro'yxatlar uchun).
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.width});

  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? {};
    final isFavorite = favorites.contains(product.id);
    final discount = discountPercent(product.price, product.oldPrice);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    ProductVisual(product: product, height: 116, fontSize: 46),
                    if (discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.gradientWarm),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-$discount%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: isFavorite
                              ? AppColors.danger
                              : AppColors.textDim,
                          size: 21,
                        ),
                        onPressed: () {
                          ref
                              .read(favoritesRepositoryProvider)
                              .toggle(product.id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 34,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingStars(rating: product.rating, size: 12),
                    const SizedBox(height: 6),
                    if (product.oldPrice != null)
                      Text(
                        formatSum(product.oldPrice!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(child: PriceText(product.price, fontSize: 14)),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            ref
                                .read(cartRepositoryProvider)
                                .add(product.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Savatga qo\u2018shildi'),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 17,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
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

/// Bo'sh holat uchun widget.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.textDim),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textDim, height: 1.4),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Yuklanmoqda holati.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

/// Buyurtma status chipi.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
