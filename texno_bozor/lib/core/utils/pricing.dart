import '../constants/app_constants.dart';
import '../../data/models/enums.dart';

/// Buyurtma summalari — yagona manba (lokal va REST rejim uchun bir xil).
///
/// Narx hisob-kitobi UI'da emas, shu yerda bajariladi. Shu sababli
/// keyinchalik server (REST + PostgreSQL) ulanganda server bilan mijoz
/// bir xil formuladan foydalanadi.
class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
  });

  /// Mahsulotlar summasi (chegirmali narxlar bo'yicha).
  final int subtotal;

  /// Eski narxlarga nisbatan tejalgan summa.
  final int discount;

  /// Yetkazib berish narxi.
  final int deliveryFee;

  /// Yakuniy to'lov summasi.
  final int total;

  /// Bepul yetkazishga qancha qolgani (0 bo'lsa — allaqachon bepul).
  int get amountToFreeDelivery {
    final left = AppConstants.freeDeliveryFrom - subtotal;
    return left > 0 ? left : 0;
  }

  bool get isFreeDelivery => deliveryFee == 0;
}

/// Yetkazib berish narxini hisoblash.
int calcDeliveryFee({
  required int subtotal,
  required DeliveryMethod delivery,
}) {
  if (subtotal <= 0) return 0;
  if (subtotal >= AppConstants.freeDeliveryFrom) return 0;
  return delivery == DeliveryMethod.express
      ? AppConstants.expressDeliveryFee
      : AppConstants.standardDeliveryFee;
}

/// Savat qatorlari asosida buyurtma summalarini hisoblash.
///
/// [lines] — har bir element: (narx, eski narx, miqdor).
OrderTotals calcOrderTotals({
  required List<({int price, int? oldPrice, int qty})> lines,
  required DeliveryMethod delivery,
}) {
  var subtotal = 0;
  var discount = 0;
  for (final line in lines) {
    final qty = line.qty < 0 ? 0 : line.qty;
    subtotal += line.price * qty;
    final old = line.oldPrice;
    if (old != null && old > line.price) {
      discount += (old - line.price) * qty;
    }
  }
  final deliveryFee = calcDeliveryFee(subtotal: subtotal, delivery: delivery);
  return OrderTotals(
    subtotal: subtotal,
    discount: discount,
    deliveryFee: deliveryFee,
    total: subtotal + deliveryFee,
  );
}
