import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/core/utils/specs.dart';
import 'package:texno_bozor/data/remote/api_mappers.dart';
import 'package:texno_bozor/data/remote/backend_config.dart';

void main() {
  group('ApiMappers — mahsulot', () {
    test('camelCase JSON to\u2018g\u2018ri o\u2018qiladi', () {
      final p = ApiMappers.product(const <String, dynamic>{
        'id': 'p1',
        'name': 'iPhone 16 Pro',
        'brand': 'Apple',
        'categoryId': 'cat_phone',
        'price': 15000000,
        'oldPrice': 17000000,
        'rating': 4.8,
        'reviewsCount': 120,
        'stock': 7,
        'specs': {'ram': '8 GB'},
        'isTop': true,
      });
      expect(p.id, 'p1');
      expect(p.categoryId, 'cat_phone');
      expect(p.price, 15000000);
      expect(p.oldPrice, 17000000);
      expect(p.rating, 4.8);
      expect(p.isTop, 1);
      expect(parseSpecs(p.specsJson)['ram'], '8 GB');
    });

    test('snake_case JSON ham qo\u2018llab-quvvatlanadi', () {
      final p = ApiMappers.product(const <String, dynamic>{
        'id': 'p2',
        'name': 'Galaxy S25',
        'category_id': 'cat_phone',
        'price': '12000000',
        'old_price': null,
        'reviews_count': '15',
        'image_url': 'https://cdn/x.jpg',
        'is_top': false,
      });
      expect(p.categoryId, 'cat_phone');
      expect(p.price, 12000000);
      expect(p.oldPrice, isNull);
      expect(p.reviewsCount, 15);
      expect(p.imageUrl, 'https://cdn/x.jpg');
      expect(p.isTop, 0);
    });

    test('yetishmayotgan maydonlar standart qiymat oladi', () {
      final p = ApiMappers.product(const <String, dynamic>{'id': 'p3'});
      expect(p.name, '');
      expect(p.price, 0);
      expect(p.specsJson, '{}');
      expect(p.warranty, '12 oy kafolat');
      expect(p.createdAt, greaterThan(0));
    });

    test('productToJson teskari konvertatsiya', () {
      final p = ApiMappers.product(const <String, dynamic>{
        'id': 'p4',
        'name': 'Test',
        'price': 100,
        'isTop': true,
      });
      final json = ApiMappers.productToJson(p);
      expect(json['id'], 'p4');
      expect(json['price'], 100);
      expect(json['isTop'], true);
    });
  });

  group('ApiMappers — kategoriya, foydalanuvchi, buyurtma', () {
    test('kategoriya', () {
      final c = ApiMappers.category(const <String, dynamic>{
        'id': 'cat_gpu',
        'name': 'Videokartalar',
        'sort_order': 3,
      });
      expect(c.id, 'cat_gpu');
      expect(c.sortOrder, 3);
      expect(c.icon, 'device');
    });

    test('foydalanuvchi', () {
      final u = ApiMappers.user(const <String, dynamic>{
        'id': 'u1',
        'name': 'Alisher',
        'phone': '+998901234567',
        'created_at': '2026-08-11T10:00:00Z',
      });
      expect(u.name, 'Alisher');
      expect(u.createdAt,
          DateTime.parse('2026-08-11T10:00:00Z').millisecondsSinceEpoch);
    });

    test('buyurtma', () {
      final o = ApiMappers.order(const <String, dynamic>{
        'id': 'ORD-1',
        'subtotal': 500000,
        'delivery_fee': 25000,
        'total': 525000,
        'payment_method': 'click',
      });
      expect(o.id, 'ORD-1');
      expect(o.deliveryFee, 25000);
      expect(o.status, 'fresh');
      expect(o.paymentMethod, 'click');
    });
  });

  group('ApiMappers — javob qobiqlari', () {
    test('listOf turli formatlarni tushunadi', () {
      expect(ApiMappers.listOf([
        {'id': 'a'},
      ]).length, 1);
      expect(ApiMappers.listOf({
        'data': [
          {'id': 'a'},
          {'id': 'b'},
        ],
      }).length, 2);
      expect(ApiMappers.listOf({
        'items': [
          {'id': 'a'},
        ],
      }).length, 1);
      expect(ApiMappers.listOf({'results': []}), isEmpty);
      expect(ApiMappers.listOf(null), isEmpty);
      expect(ApiMappers.listOf('xato'), isEmpty);
    });

    test('objectOf data qobig\u2018ini ochadi', () {
      expect(
        ApiMappers.objectOf(<String, dynamic>{
          'data': <String, dynamic>{'id': 'x'},
        })?['id'],
        'x',
      );
      expect(ApiMappers.objectOf(<String, dynamic>{'id': 'y'})?['id'], 'y');
      expect(ApiMappers.objectOf(null), isNull);
    });
  });

  group('BackendConfig', () {
    test('sukut bo\u2018yicha lokal rejim', () {
      const config = BackendConfig();
      expect(config.mode, BackendMode.local);
      expect(config.isRemote, isFalse);
    });

    test('manzilsiz remote rejim ishlamaydi', () {
      const config = BackendConfig(mode: BackendMode.remote, baseUrl: '  ');
      expect(config.isRemote, isFalse);
    });

    test('manzil bilan remote rejim yoqiladi', () {
      const config = BackendConfig(
        mode: BackendMode.remote,
        baseUrl: 'https://api.texnobozor.uz/v1',
      );
      expect(config.isRemote, isTrue);
    });

    test('copyWith va tenglik', () {
      const a = BackendConfig(baseUrl: 'https://a');
      final b = a.copyWith(mode: BackendMode.remote);
      expect(b.baseUrl, 'https://a');
      expect(b.mode, BackendMode.remote);
      expect(a == a.copyWith(), isTrue);
      expect(a == b, isFalse);
      expect(a.hashCode, a.copyWith().hashCode);
    });

    test('nomdan rejim tiklanadi', () {
      expect(BackendMode.fromName('remote'), BackendMode.remote);
      expect(BackendMode.fromName('yoq'), BackendMode.local);
      expect(BackendMode.fromName(null), BackendMode.local);
    });
  });
}
