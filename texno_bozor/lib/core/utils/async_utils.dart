/// Fon rejimidagi vazifani kutmasdan ishga tushirish.
///
/// Xatolik yuzaga kelsa ilova qulamaydi — offline rejimda tarmoq
/// so'rovlari muvaffaqiyatsiz bo'lishi normal holat.
void fireAndForget(Future<void> Function() task) {
  Future<void>(() async {
    try {
      await task();
    } catch (_) {
      // Jim o'tamiz: lokal kesh ishlatiladi.
    }
  });
}
