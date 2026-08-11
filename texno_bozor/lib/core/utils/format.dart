/// Formatlash yordamchilari — narx, sana, telefon.
class Format {
  const Format._();

  static const List<String> _months = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  /// 12500000 -> "12 500 000"
  static String number(num value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  /// 12500000 -> "12 500 000 so'm"
  static String price(num value) => '${number(value)} so\u2018m';

  /// 12500000 -> "12,5 mln"
  static String shortPrice(num value) {
    if (value >= 1000000) {
      final mln = value / 1000000;
      final text = mln >= 10
          ? mln.round().toString()
          : mln.toStringAsFixed(1).replaceAll('.', ',');
      return '$text mln';
    }
    if (value >= 1000) return '${(value / 1000).round()} ming';
    return number(value);
  }

  /// 11.08.2026
  static String date(DateTime dt) =>
      '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';

  /// 11-avgust, 14:30
  static String dateTime(DateTime dt) =>
      '${dt.day}-${_months[dt.month - 1]}, ${_two(dt.hour)}:${_two(dt.minute)}';

  /// "Bugun 14:30" / "Kecha" / "3 kun oldin" / "11.08.2026"
  static String relative(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;

    if (diff == 0) return 'Bugun ${_two(dt.hour)}:${_two(dt.minute)}';
    if (diff == 1) return 'Kecha ${_two(dt.hour)}:${_two(dt.minute)}';
    if (diff < 7) return '$diff kun oldin';
    return date(dt);
  }

  /// 998901234567 -> "+998 90 123 45 67"
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) return raw;
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10)}';
  }

  /// Telefon raqami to'g'rimi? (O'zbekiston formati)
  static bool isValidPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 && digits.startsWith('998');
  }

  static String rating(double value) => value.toStringAsFixed(1);

  static String _two(int value) => value.toString().padLeft(2, '0');
}
