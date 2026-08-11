import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/database/app_database.dart';
import 'package:texno_bozor/data/models/enums.dart';
import 'package:texno_bozor/data/repositories/cart_repository.dart';
import 'package:texno_bozor/data/repositories/category_repository.dart';
import 'package:texno_bozor/data/repositories/favorites_repository.dart';
import 'package:texno_bozor/data/repositories/history_repository.dart';
import 'package:texno_bozor/data/repositories/order_repository.dart';
import 'package:texno_bozor/data/repositories/pc_build_repository.dart';
import 'package:texno_bozor/data/repositories/product_repository.dart';
import 'package:texno_bozor/data/repositories/review_repository.dart';
import 'package:texno_bozor/data/repositories/user_repository.dart';
import 'package:texno_bozor/data/services/auth_service.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  group('ProductRepository', () {
    test('seed katalog yuklanadi', () async {
      final repo = DriftProductRepository(db);
      final products = await repo.getAll();
      expect(products.length, greaterThan(50));
      expect(products.every((p) => p.price > 0), isTrue);
      expect(products.every((p) => p.id.isNotEmpty), isTrue);
    });

    test('har bir mahsulot mavjud kategoriyaga tegishli', () async {
      final products = await DriftProductRepository(db).getAll();
      final categories = await db.select(db.categories).get();
      final ids = categories.map((c) => c.id).toSet();
      for (final p in products) {
        expect(ids.contains(p.categoryId), isTrue,
            reason: '${p.name} -> ${p.categoryId} kategoriyasi yo\u2018q');
      }
    });

    test('qidiruv nom va brend bo\u2018yicha ishlaydi', () async {
      final repo = DriftProductRepository(db);
      final all = await repo.getAll();
      final sample = all.first;

      final byName = await repo.search(sample.name);
      expect(byName.map((p) => p.id), contains(sample.id));

      final byBrand = await repo.search(sample.brand);
      expect(byBrand, isNotEmpty);

      expect(await repo.search('   '), isEmpty);
      expect(await repo.search('zzzz-yoq-mahsulot'), isEmpty);
    });

    test('brendlar ro\u2018yxati takrorlanmaydi', () async {
      final brands = await DriftProductRepository(db).brands();
      expect(brands.length, brands.toSet().length);
      expect(brands, isNotEmpty);
    });

    test('id bo\u2018yicha topish', () async {
      final repo = DriftProductRepository(db);
      final first = (await repo.getAll()).first;
      expect((await repo.getById(first.id))?.name, first.name);
      expect(await repo.getById('yoq-id'), isNull);
    });
  });

  group('CategoryRepository', () {
    test('kategoriyalar tartib bo\u2018yicha keladi', () async {
      final repo = DriftCategoryRepository(db);
      final categories = await repo.watchAll().first;
      expect(categories, isNotEmpty);
      final orders = categories.map((c) => c.sortOrder).toList();
      final sorted = [...orders]..sort();
      expect(orders, sorted);
    });
  });

  group('CartRepository', () {
    test('qo\u2018shish, miqdorni o\u2018zgartirish, o\u2018chirish', () async {
      final cart = DriftCartRepository(db);
      final product = (await DriftProductRepository(db).getAll()).first;

      await cart.add(product.id);
      var items = await cart.getItems();
      expect(items.length, 1);
      expect(items.first.qty, 1);

      // Takror qo'shilsa miqdor oshadi (yangi qator emas).
      await cart.add(product.id, qty: 2);
      items = await cart.getItems();
      expect(items.length, 1);
      expect(items.first.qty, 3);

      await cart.setQty(product.id, 5);
      expect((await cart.getItems()).first.qty, 5);

      // 0 ga tushirilsa savatdan chiqadi.
      await cart.setQty(product.id, 0);
      expect(await cart.getItems(), isEmpty);

      await cart.add(product.id);
      await cart.clear();
      expect(await cart.getItems(), isEmpty);
    });

    test('savat summasi to\u2018g\u2018ri hisoblanadi', () async {
      final cart = DriftCartRepository(db);
      final product = (await DriftProductRepository(db).getAll()).first;
      await cart.add(product.id, qty: 3);
      final entry = (await cart.getItems()).first;
      expect(entry.total, product.price * 3);
    });
  });

  group('OrderRepository', () {
    test('savatdan buyurtma yaratiladi va savat tozalanadi', () async {
      final cart = DriftCartRepository(db);
      final orders = DriftOrderRepository(db, cart);
      final products = await DriftProductRepository(db).getAll();
      final p1 = products[0];
      final p2 = products[1];

      await cart.add(p1.id, qty: 2);
      await cart.add(p2.id);

      final order = await orders.createFromCart(
        address: 'Toshkent, Chilonzor 9-kvartal',
        payment: PaymentMethod.cash,
        delivery: DeliveryMethod.standard,
        customerName: 'Alisher',
        customerPhone: '+998901234567',
      );

      expect(order.id, startsWith('ORD-'));
      expect(order.subtotal, p1.price * 2 + p2.price);
      expect(order.total, order.subtotal + order.deliveryFee);
      expect(order.status, OrderStatus.fresh.name);

      // Savat tozalangan.
      expect(await cart.getItems(), isEmpty);

      // Buyurtma tarkibi saqlangan.
      final items = await orders.watchItems(order.id).first;
      expect(items.length, 2);
      expect(items.map((i) => i.productId), containsAll([p1.id, p2.id]));

      // Ombordan ayirilgan.
      final updated = await DriftProductRepository(db).getById(p1.id);
      expect(updated!.stock, p1.stock - 2);
    });

    test('bo\u2018sh savatdan buyurtma yaratilmaydi', () async {
      final cart = DriftCartRepository(db);
      final orders = DriftOrderRepository(db, cart);
      await expectLater(
        orders.createFromCart(
          address: 'Toshkent',
          payment: PaymentMethod.cash,
          delivery: DeliveryMethod.standard,
          customerName: 'A',
          customerPhone: '+998900000000',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('status yangilanadi', () async {
      final cart = DriftCartRepository(db);
      final orders = DriftOrderRepository(db, cart);
      final product = (await DriftProductRepository(db).getAll()).first;
      await cart.add(product.id);
      final order = await orders.createFromCart(
        address: 'Toshkent, Yunusobod',
        payment: PaymentMethod.click,
        delivery: DeliveryMethod.express,
        customerName: 'Bek',
        customerPhone: '+998901112233',
      );

      await orders.updateStatus(order.id, OrderStatus.delivered);
      final updated = await orders.watchById(order.id).first;
      expect(updated!.status, OrderStatus.delivered.name);
    });
  });

  group('FavoritesRepository', () {
    test('toggle sevimlilarni qo\u2018shadi va olib tashlaydi', () async {
      final favorites = DriftFavoritesRepository(db);
      final product = (await DriftProductRepository(db).getAll()).first;

      expect(await favorites.isFavorite(product.id), isFalse);
      await favorites.toggle(product.id);
      expect(await favorites.isFavorite(product.id), isTrue);
      expect((await favorites.watchIds().first), contains(product.id));
      expect((await favorites.watchProducts().first).first.id, product.id);

      await favorites.toggle(product.id);
      expect(await favorites.isFavorite(product.id), isFalse);
    });
  });

  group('ReviewRepository', () {
    test('sharh qo\u2018shilsa reyting qayta hisoblanadi', () async {
      final reviews = DriftReviewRepository(db);
      final products = DriftProductRepository(db);
      final product = (await products.getAll()).first;

      await reviews.addReview(
        id: 'r1',
        productId: product.id,
        userName: 'Alisher',
        rating: 5,
        text: 'Zo\u2018r mahsulot',
      );
      await reviews.addReview(
        id: 'r2',
        productId: product.id,
        userName: 'Dilnoza',
        rating: 3,
        text: 'Yaxshi',
      );

      final updated = await products.getById(product.id);
      expect(updated!.reviewsCount, 2);
      expect(updated.rating, closeTo(4.0, 0.001));
      expect((await reviews.watchForProduct(product.id).first).length, 2);
    });
  });

  group('HistoryRepository', () {
    test('qidiruv tarixi takrorlanmaydi va tozalanadi', () async {
      final history = DriftHistoryRepository(db);
      await history.addSearch('rtx 5070');
      await history.addSearch('iphone');
      await history.addSearch('rtx 5070');
      await history.addSearch('   ');

      final entries = await history.watchSearchHistory().first;
      expect(entries.length, 2);
      expect(entries.map((e) => e.query), containsAll(['rtx 5070', 'iphone']));

      await history.clearSearchHistory();
      expect(await history.watchSearchHistory().first, isEmpty);
    });

    test('yaqinda ko\u2018rilganlar saqlanadi', () async {
      final history = DriftHistoryRepository(db);
      final product = (await DriftProductRepository(db).getAll()).first;
      await history.addViewed(product.id);
      final viewed = await history.watchRecentlyViewed().first;
      expect(viewed.map((p) => p.id), contains(product.id));
    });
  });

  group('UserRepository + AuthService', () {
    test('login profil yaratadi, logout o\u2018chiradi', () async {
      final users = DriftUserRepository(db);
      final auth = LocalAuthService(users);

      expect(await auth.currentUser(), isNull);

      final user = await auth.login(name: 'Alisher', phone: '+998901234567');
      expect(user.name, 'Alisher');
      expect((await auth.currentUser())?.phone, '+998901234567');

      // Takroriy login mavjud profilni yangilaydi.
      final again = await auth.login(name: 'Alisher Aliev', phone: '+998900000000');
      expect(again.id, user.id);
      expect((await users.getFirst())?.name, 'Alisher Aliev');

      await auth.logout();
      expect(await auth.currentUser(), isNull);
    });

    test('profil manzili yangilanadi', () async {
      final users = DriftUserRepository(db);
      final user = await users.create(id: 'u1', name: 'Bek', phone: '+99890');
      await users.update(user.copyWith(address: 'Toshkent, Mirzo Ulug\u2018bek'));
      expect((await users.getFirst())?.address, 'Toshkent, Mirzo Ulug\u2018bek');
    });
  });

  group('PcBuildRepository', () {
    test('yig\u2018ilma saqlanadi va o\u2018chiriladi', () async {
      final builds = DriftPcBuildRepository(db);
      await builds.save(
        id: 'b1',
        name: 'Gaming PC',
        componentsJson: '{"cpu":"cpu_1"}',
        totalPrice: 15000000,
      );
      var list = await builds.watchAll().first;
      expect(list.length, 1);
      expect(list.first.totalPrice, 15000000);

      await builds.delete('b1');
      list = await builds.watchAll().first;
      expect(list, isEmpty);
    });
  });
}
