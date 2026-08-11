import '../models/enums.dart';

/// To'lov natijasi.
class PaymentResult {
  const PaymentResult({required this.success, required this.message});
  final bool success;
  final String message;
}

/// To'lov abstraksiyasi.
///
/// Hozircha REAL Click/Payme/Uzcard/Humo integratsiyasi YO'Q —
/// buyurtma lokal test rejimida yaratiladi. Server ulanganda shu
/// interfeysga haqiqiy provayder implementatsiyalari qo'shiladi.
abstract class PaymentService {
  /// Rejim tavsifi (UI'da ko'rsatiladi).
  String get modeLabel;

  Future<PaymentResult> pay({
    required PaymentMethod method,
    required int amount,
    required String orderId,
  });
}

/// Lokal test to'lov xizmati — server ulanishini kutmasdan ishlaydi.
class LocalTestPaymentService implements PaymentService {
  @override
  String get modeLabel => 'Test rejimi';

  @override
  Future<PaymentResult> pay({
    required PaymentMethod method,
    required int amount,
    required String orderId,
  }) async {
    // Real to'lov gateway'ini imitatsiya qilish.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const PaymentResult(
      success: true,
      message: 'To\u2018lov test rejimida qabul qilindi',
    );
  }
}
