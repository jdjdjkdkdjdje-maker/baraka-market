import '../database/app_database.dart';
import 'enums.dart';

/// Savat yozuvi: mahsulot + miqdor (join natijasi).
class CartEntry {
  const CartEntry({required this.product, required this.qty});
  final Product product;
  final int qty;

  int get total => product.price * qty;
  int get totalDiscount =>
      product.oldPrice == null
          ? 0
          : (product.oldPrice! - product.price) * qty;
}

/// Katalog filtri.
class ProductFilter {
  const ProductFilter({
    this.categoryId,
    this.brands = const {},
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.sort = ProductSort.popular,
  });

  final String? categoryId;
  final Set<String> brands;
  final int? minPrice;
  final int? maxPrice;
  final double minRating;
  final ProductSort sort;

  bool get hasActiveFilters =>
      brands.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minRating > 0;

  int get activeFilterCount {
    var n = 0;
    if (brands.isNotEmpty) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (minRating > 0) n++;
    return n;
  }

  ProductFilter copyWith({
    String? Function()? categoryId,
    Set<String>? brands,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    double? minRating,
    ProductSort? sort,
  }) {
    return ProductFilter(
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      brands: brands ?? this.brands,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
    );
  }
}

/// Bosh sahifa banneri.
class BannerData {
  const BannerData({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.route,
    required this.gradientIndex,
  });

  final String title;
  final String subtitle;
  final String emoji;

  /// Bosilganda ochiladigan route.
  final String route;
  final int gradientIndex;
}

/// TEXNO AI chat xabari.
class AiMessage {
  const AiMessage({required this.role, required this.text});

  /// 'user' yoki 'assistant'
  final String role;
  final String text;

  bool get isUser => role == 'user';
}

/// PC Builder moslik tekshiruvi natijasi.
class CompatCheck {
  const CompatCheck({required this.ok, required this.title, this.details = ''});
  final bool ok;
  final String title;
  final String details;
}
