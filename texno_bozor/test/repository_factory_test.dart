import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/local/app_database.dart';
import 'package:texno_bozor/data/remote/api_client.dart';
import 'package:texno_bozor/data/repositories/api/api_repositories.dart';
import 'package:texno_bozor/data/repositories/local/local_cart_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_category_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_order_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_product_repository.dart';
import 'package:texno_bozor/data/repositories/repositories.dart';
import 'package:texno_bozor/data/repositories/repository_factory.dart';

import 'helpers/test_database.dart';

/// Repository pattern shartnomasi: implementatsiyani almashtirish mumkinmi?
void main() {
  late AppDatabase db;

  setUp(() async => db = await openTestDatabase());
  tearDown(() => db.close());

  group('Lokal rejim (offline)', () {
    test('barcha omborlar SQLite implementatsiyasi', () {
      final factory = RepositoryFactory(db: db);
      expect(factory.isRemote, isFalse);
      expect(factory.products, isA<LocalProductRepository>());
      expect(factory.categories, isA<LocalCategoryRepository>());
      expect(factory.cart, isA<LocalCartRepository>());
      expect(factory.orders, isA<LocalOrderRepository>());
    });

    test('bo\u2018sh baseUrl server rejimini yoqmaydi', () {
      final factory =
          RepositoryFactory(db: db, config: const ApiConfig(baseUrl: '  '));
      expect(factory.isRemote, isFalse);
      expect(factory.products, isA<LocalProductRepository>());
    });
  });

  group('Server rejimi (REST API)', () {
    RepositoryFactory remote() => RepositoryFactory(
          db: db,
          config: const ApiConfig(
            baseUrl: 'https://api.texnobozor.uz/v1',
            token: 'test-token',
          ),
        );

    test('almashtiriladigan omborlar REST implementatsiyasi', () {
      final factory = remote();
      expect(factory.isRemote, isTrue);
      expect(factory.products, isA<ApiProductRepository>());
      expect(factory.categories, isA<ApiCategoryRepository>());
      expect(factory.cart, isA<ApiCartRepository>());
      expect(factory.orders, isA<ApiOrderRepository>());
      expect(factory.users, isA<ApiUserRepository>());
      factory.dispose();
    });

    test('interfeys shartnomasi saqlanadi', () {
      final factory = remote();
      expect(factory.products, isA<ProductRepository>());
      expect(factory.categories, isA<CategoryRepository>());
      expect(factory.cart, isA<CartRepository>());
      expect(factory.orders, isA<OrderRepository>());
      expect(factory.users, isA<UserRepository>());
      factory.dispose();
    });

    test('qurilma ichidagi ma\u2018lumot lokal qoladi', () {
      final factory = remote();
      expect(factory.favorites, isA<FavoritesRepository>());
      expect(factory.history, isA<HistoryRepository>());
      expect(factory.pcBuilds, isA<PcBuildRepository>());
      expect(factory.chat, isA<ChatRepository>());
      factory.dispose();
    });
  });

  group('Offline fallback', () {
    test('server javob bermasa lokal ma\u2018lumot qaytadi', () async {
      // Mavjud bo'lmagan manzil — so'rov albatta xato beradi.
      final factory = RepositoryFactory(
        db: db,
        config: const ApiConfig(baseUrl: 'http://127.0.0.1:9'),
      );
      final products = await factory.products.getAll();
      expect(products, isNotEmpty,
          reason: 'API ishlamasa lokal katalog ko\u2018rsatilishi kerak');

      final categories = await factory.categories.getAll();
      expect(categories, isNotEmpty);
      factory.dispose();
    });
  });

  group('ApiClient', () {
    test('baseUrl bo\u2018sh bo\u2018lsa xato beradi', () {
      final client = ApiClient(const ApiConfig());
      expect(() => client.get('/products'), throwsA(isA<ApiException>()));
      client.close();
    });

    test('javobdan ro\u2018yxat ajratadi', () {
      expect(ApiClient.listOf([
        {'id': '1'}
      ]).length, 1);
      expect(
        ApiClient.listOf({
          'data': [
            {'id': '1'},
            {'id': '2'}
          ]
        }).length,
        2,
      );
      expect(ApiClient.listOf('xato'), isEmpty);
    });

    test('javobdan obyekt ajratadi', () {
      expect(ApiClient.objectOf({'id': '1'})?['id'], '1');
      expect(
        ApiClient.objectOf({
          'data': {'id': '2'}
        })?['id'],
        '2',
      );
      expect(ApiClient.objectOf(null), isNull);
    });
  });

  group('ApiMappers', () {
    test('serverdagi JSON mahsulotga aylanadi', () {
      final product = ApiMappers.product({
        'id': 'p1',
        'name': 'Test',
        'brand': 'Brand',
        'category_id': 'cpu',
        'price': 1000,
        'old_price': 1500,
        'rating': 4.5,
        'specs': {'socket': 'AM5'},
      });
      expect(product.id, 'p1');
      expect(product.price, 1000);
      expect(product.discountPercent, 33);
      expect(product.spec('socket'), 'AM5');
    });

    test('camelCase kalitlar ham qo\u2018llanadi', () {
      final product = ApiMappers.product({
        'id': 'p2',
        'name': 'X',
        'categoryId': 'gpu',
        'oldPrice': 200,
        'price': 100,
      });
      expect(product.categoryId, 'gpu');
      expect(product.oldPrice, 200);
    });
  });
}
