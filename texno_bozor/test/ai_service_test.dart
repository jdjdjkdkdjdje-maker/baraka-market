import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/models/models.dart';
import 'package:texno_bozor/data/services/ai_service.dart';

List<Product> catalog() => [
      const Product(
        id: 'ph-1',
        name: 'Redmi Note 13',
        brand: 'Xiaomi',
        categoryId: 'phones',
        price: 3000000,
        rating: 4.7,
        stock: 10,
        popularity: 90,
      ),
      const Product(
        id: 'ph-2',
        name: 'iPhone 15 Pro',
        brand: 'Apple',
        categoryId: 'phones',
        price: 18000000,
        rating: 4.9,
        stock: 5,
        popularity: 95,
      ),
      const Product(
        id: 'hp-1',
        name: 'JBL Tune 520BT',
        brand: 'JBL',
        categoryId: 'headphones',
        price: 690000,
        rating: 4.5,
        stock: 20,
        popularity: 85,
      ),
      const Product(
        id: 'hp-2',
        name: 'AirPods Pro 2',
        brand: 'Apple',
        categoryId: 'headphones',
        price: 3200000,
        rating: 4.9,
        stock: 8,
        popularity: 98,
      ),
      const Product(
        id: 'lap-1',
        name: 'ASUS TUF Gaming F15',
        brand: 'ASUS',
        categoryId: 'laptops',
        price: 13500000,
        rating: 4.7,
        stock: 4,
        popularity: 92,
      ),
    ];

void main() {
  group('parseBudget', () {
    test('million formatlari', () {
      expect(AiService.parseBudget('15 mln so\u2018mgacha'), 15000000);
      expect(AiService.parseBudget('2,5 mln'), 2500000);
      expect(AiService.parseBudget('3 million'), 3000000);
    });

    test('ming formatlari', () {
      expect(AiService.parseBudget('500 ming so\u2018m'), 500000);
      expect(AiService.parseBudget('800 ming'), 800000);
    });

    test('to\u2018liq raqam', () {
      expect(AiService.parseBudget('3000000 so\u2018m'), 3000000);
    });

    test('byudjet yo\u2018q bo\u2018lsa null', () {
      expect(AiService.parseBudget('yaxshi telefon kerak'), isNull);
    });
  });

  group('detectCategory', () {
    test('kategoriya kalit so\u2018zlarini taniydi', () {
      expect(AiService.detectCategory('menga noutbuk kerak'), 'laptops');
      expect(AiService.detectCategory('yaxshi smartfon'), 'phones');
      expect(AiService.detectCategory('quloqchin tanlab ber'), 'headphones');
      expect(AiService.detectCategory('rtx 4060 bormi'), 'gpu');
      expect(AiService.detectCategory('ssd disk kerak'), 'ssd');
    });

    test('noma\u2018lum mavzu null qaytaradi', () {
      expect(AiService.detectCategory('bugun ob-havo qanday'), isNull);
    });
  });

  group('offlineAnswer', () {
    test('salomlashishga javob beradi', () {
      final reply = AiService.offlineAnswer(
        question: 'Salom',
        catalog: catalog(),
      );
      expect(reply.text, contains('TEXNO AI'));
      expect(reply.online, isFalse);
    });

    test('bo\u2018sh savolga yo\u2018riqnoma beradi', () {
      final reply = AiService.offlineAnswer(question: '  ', catalog: catalog());
      expect(reply.text, contains('Savolingizni'));
    });

    test('byudjet va kategoriya bo\u2018yicha tanlaydi', () {
      final reply = AiService.offlineAnswer(
        question: '1 mln so\u2018mgacha quloqchin kerak',
        catalog: catalog(),
      );
      expect(reply.productIds, contains('hp-1'));
      expect(reply.productIds, isNot(contains('hp-2')));
    });

    test('kategoriya bo\u2018yicha filtrlaydi', () {
      final reply = AiService.offlineAnswer(
        question: 'noutbuk tavsiya qiling',
        catalog: catalog(),
      );
      expect(reply.productIds, ['lap-1']);
    });

    test('byudjet juda kam bo\u2018lsa arzonlarni taklif qiladi', () {
      final reply = AiService.offlineAnswer(
        question: '100 ming so\u2018mga telefon',
        catalog: catalog(),
      );
      expect(reply.text, contains('topilmadi'));
      expect(reply.productIds, isNotEmpty);
    });

    test('reyting yuqori mahsulotni birinchi qo\u2018yadi', () {
      final reply = AiService.offlineAnswer(
        question: 'eng yaxshi quloqchin',
        catalog: catalog(),
      );
      expect(reply.productIds.first, 'hp-2');
    });

    test('javob har doim mahsulot ID qaytaradi', () {
      final reply = AiService.offlineAnswer(
        question: 'telefon',
        catalog: catalog(),
      );
      expect(reply.productIds.length, lessThanOrEqualTo(3));
      final ids = {for (final p in catalog()) p.id};
      expect(reply.productIds.every(ids.contains), isTrue);
    });
  });

  group('AiConfig', () {
    test('kalitsiz oflayn rejim', () {
      expect(const AiConfig().isEnabled, isFalse);
      expect(const AiConfig(apiKey: 'sk-1').isEnabled, isTrue);
    });
  });

  group('ask', () {
    test('kalitsiz holatda oflayn javob qaytaradi', () async {
      final service = AiService();
      final reply = await service.ask(
        question: 'quloqchin 1 mln gacha',
        catalog: catalog(),
        history: const [],
      );
      expect(reply.online, isFalse);
      expect(reply.productIds, isNotEmpty);
      service.close();
    });
  });
}
