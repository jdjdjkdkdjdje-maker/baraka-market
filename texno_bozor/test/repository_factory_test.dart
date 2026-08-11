import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/database/app_database.dart';
import 'package:texno_bozor/data/remote/backend_config.dart';
import 'package:texno_bozor/data/repositories/api/api_cart_repository.dart';
import 'package:texno_bozor/data/repositories/api/api_category_repository.dart';
import 'package:texno_bozor/data/repositories/api/api_order_repository.dart';
import 'package:texno_bozor/data/repositories/api/api_product_repository.dart';
import 'package:texno_bozor/data/repositories/api/api_user_repository.dart';
import 'package:texno_bozor/data/repositories/cart_repository.dart';
import 'package:texno_bozor/data/repositories/category_repository.dart';
import 'package:texno_bozor/data/repositories/order_repository.dart';
import 'package:texno_bozor/data/repositories/product_repository.dart';
import 'package:texno_bozor/data/repositories/repository_factory.dart';
import 'package:texno_bozor/data/repositories/user_repository.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  group('RepositoryFactory — lokal rejim', () {
    test('barcha omborlar Drift implementatsiyasi', () {
      final factory = RepositoryFactory(db: db, config: const BackendConfig());
      expect(factory.isRemote, isFalse);
      expect(factory.products(), isA<DriftProductRepository>());
      expect(factory.categories(), isA<DriftCategoryRepository>());
      expect(factory.cart(), isA<DriftCartRepository>());
      expect(factory.orders(factory.cart()), isA<DriftOrderRepository>());
      expect(factory.users(), isA<DriftUserRepository>());
    });

    test('server manzili bo\u2018sh bo\u2018lsa remote rejim yoqilmaydi', () {
      final factory = RepositoryFactory(
        db: db,
        config: const BackendConfig(mode: BackendMode.remote),
      );
      expect(factory.isRemote, isFalse);
      expect(factory.products(), isA<DriftProductRepository>());
    });
  });

  group('RepositoryFactory — server rejimi', () {
    RepositoryFactory remoteFactory() => RepositoryFactory(
          db: db,
          config: const BackendConfig(
            mode: BackendMode.remote,
            baseUrl: 'https://api.texnobozor.uz/v1',
            token: 'test-token',
          ),
        );

    test('almashtiriladigan omborlar REST implementatsiyasi', () {
      final factory = remoteFactory();
      expect(factory.isRemote, isTrue);
      expect(factory.products(), isA<ApiProductRepository>());
      expect(factory.categories(), isA<ApiCategoryRepository>());
      expect(factory.cart(), isA<ApiCartRepository>());
      expect(factory.orders(factory.cart()), isA<ApiOrderRepository>());
      expect(factory.users(), isA<ApiUserRepository>());
    });

    test('omborlar interfeys shartnomasini saqlaydi', () {
      final factory = remoteFactory();
      expect(factory.products(), isA<ProductRepository>());
      expect(factory.categories(), isA<CategoryRepository>());
      expect(factory.cart(), isA<CartRepository>());
      expect(factory.orders(factory.cart()), isA<OrderRepository>());
      expect(factory.users(), isA<UserRepository>());
    });

    test('qurilma ichidagi ma\u2018lumot server rejimida ham lokal qoladi', () {
      final factory = remoteFactory();
      expect(factory.favorites().runtimeType.toString(),
          startsWith('DriftFavorites'));
      expect(factory.history().runtimeType.toString(), startsWith('DriftHistory'));
      expect(factory.reviews().runtimeType.toString(), startsWith('DriftReview'));
      expect(factory.pcBuilds().runtimeType.toString(), startsWith('DriftPcBuild'));
    });
  });
}
