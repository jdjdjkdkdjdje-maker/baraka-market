import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/core/utils/format.dart';

void main() {
  group('Format.number', () {
    test('minglarga ajratadi', () {
      expect(Format.number(12500000).replaceAll('\u00A0', ' '), '12 500 000');
      expect(Format.number(999), '999');
      expect(Format.number(1000).replaceAll('\u00A0', ' '), '1 000');
    });
  });

  group('Format.price', () {
    test('so\u2018m qo\u2018shadi', () {
      expect(Format.price(5000).replaceAll('\u00A0', ' '), '5 000 so\u2018m');
    });
  });

  group('Format.shortPrice', () {
    test('million va mingga qisqartiradi', () {
      expect(Format.shortPrice(12500000), '12 mln');
      expect(Format.shortPrice(1500000), '1,5 mln');
      expect(Format.shortPrice(450000), '450 ming');
      expect(Format.shortPrice(500), '500');
    });
  });

  group('Format.phone', () {
    test('O\u2018zbekiston formatida ko\u2018rsatadi', () {
      expect(Format.phone('998901234567'), '+998 90 123 45 67');
    });

    test('noto\u2018g\u2018ri raqamni o\u2018zgartirmaydi', () {
      expect(Format.phone('12345'), '12345');
    });
  });

  group('Format.isValidPhone', () {
    test('to\u2018g\u2018ri raqamlarni qabul qiladi', () {
      expect(Format.isValidPhone('+998 90 123 45 67'), isTrue);
      expect(Format.isValidPhone('998901234567'), isTrue);
    });

    test('xato raqamlarni rad etadi', () {
      expect(Format.isValidPhone('901234567'), isFalse);
      expect(Format.isValidPhone('+7 900 123 45 67'), isFalse);
      expect(Format.isValidPhone(''), isFalse);
    });
  });

  group('Format.relative', () {
    test('bugungi sanani "Bugun" deb yozadi', () {
      final now = DateTime.now();
      expect(Format.relative(now), startsWith('Bugun'));
    });

    test('kechagi sanani "Kecha" deb yozadi', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(Format.relative(yesterday), startsWith('Kecha'));
    });
  });
}
