/// Narx va sana formatlash funksiyalari.
library;

/// 1234500 -> "1 234 500 so'm"
String formatSum(int sum) {
  final negative = sum < 0;
  final s = sum.abs().toString();
  final buffer = StringBuffer();
  var count = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count % 3 == 0 && i > 0) buffer.write('\u2009');
  }
  final formatted = buffer.toString().split('').reversed.join();
  return '${negative ? '-' : ''}$formatted so\u2018m';
}

/// 1234500 -> "1 234 500"
String formatNumber(int sum) {
  final s = sum.toString();
  final buffer = StringBuffer();
  var count = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count % 3 == 0 && i > 0) buffer.write('\u2009');
  }
  return buffer.toString().split('').reversed.join();
}

String _two(int n) => n < 10 ? '0$n' : '$n';

/// 11.08.2026 14:30
String formatDateTime(DateTime dt) {
  return '${_two(dt.day)}.${_two(dt.month)}.${dt.year} ${_two(dt.hour)}:${_two(dt.minute)}';
}

/// 11.08.2026
String formatDate(DateTime dt) {
  return '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';
}

/// Chegirma foizi: eski narx va yangi narx bo'yicha.
int discountPercent(int price, int? oldPrice) {
  if (oldPrice == null || oldPrice <= price || oldPrice == 0) return 0;
  return (((oldPrice - price) / oldPrice) * 100).round();
}
