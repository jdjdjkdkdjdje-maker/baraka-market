import 'package:connectivity_plus/connectivity_plus.dart';

/// Internet holatini tekshirish. Ilovaning asosiy qismi internetsiz
/// ishlaydi; internet faqat TEXNO AI uchun kerak.
class ConnectivityService {
  Future<bool> get isOnline async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Tekshirib bo'lmasa, urinib ko'rishga ruxsat beramiz.
      return true;
    }
  }

  Stream<bool> get onConnectivityChanged {
    return Connectivity()
        .onConnectivityChanged
        .map((list) => list.any((r) => r != ConnectivityResult.none));
  }
}
