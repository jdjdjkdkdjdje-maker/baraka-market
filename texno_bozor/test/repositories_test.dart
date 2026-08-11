import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/local/app_database.dart';
import 'package:texno_bozor/data/models/models.dart';
import 'package:texno_bozor/data/repositories/local/local_cart_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_category_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_misc_repositories.dart';
import 'package:texno_bozor/data/repositories/local/local_order_repository.dart';
import 'package:texno_bozor/data/repositories/local/local_product_repository.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late LocalProductRepository products;
  late LocalCategoryRepository categories;
  late LocalCartRepository cart;
  late LocalOrderRepository orders;

  setUp(() async {
    db = await openTestDatabase();
    products = LocalProductRepository(db);
    categories = LocalCategoryRepository(db);
    cart = LocalCartRepository(db, products);
    orders = LocalOrderRepository(db, cart, products);
  });

  tearDown(() => db.close());

  group('Katalog seed', () {
    test('mahsulotlar va kategoriyalar yozilgan', () async {
      expect((await products.getAll()).length, greaterThan(50));
      expect((await categories.getAll()).length, greaterThan(20));
    });

    test('har bir mahsulot mavjud kategoriyaga tegishli', () async {
      final ids = {for (final c in await categories.getAll()) c.id};
      for (final product in await products.getAll()) {
        expect(ids, contains(product.categoryId),
            reason: '${product.id} noma\u2018lum kategoriyada');
      }
    });

    test('narxlar musbat va chegirma mantiqiy', () async {
      for (final product in await products.getAll()) {
        expect(product.price, greaterThan(0));
        if (product.oldPrice > 0) {
          expect(product.oldPrice, greaterThan(product.price));
          expect(product.discountPercent, inInclusiveRange(1, 90));
        }
      }
    });
  });

  group('ProductRepository', () {
    test('getById mahsulotni topadi', () async {
      final all = await products.getAll();
      final found = await products.getById(all.first.id);
      expect(found?.name, all.first.name);
    });

    test('getById mavjud bo\u2018lmaganda null', () async {
      expect(await products.getById('yoq-bunday-id'), isNull);
    });

    test('qidiruv nom bo\u2018yicha topadi', () async {
      final results = await products.search('RTX 4060');
      expect(results, isNotEmpty);
      expect(results.first.name.toLowerCase(), contains('4060'));
    });

    test('qidiruv brend bo\u2018yicha ishlaydi', () async {
      final results = await products.search('Samsung');
      expect(results, isNotEmpty);
      expect(results.every((p) =>
          '${p.name} ${p.brand} ${p.description}'
              .toLowerCase()
              .contains('samsung')),
          isTrue);
    });

    test('bo\u2018sh qidiruv bo\u2018sh natija qaytaradi', () async {
      expect(await products.search('   '), isEmpty);
    });

    test('mavjud bo\u2018lmagan so\u2018z natija bermaydi', () async {
      expect(await products.search('qwertyuiopasdfgh'), isEmpty);
    });

    test('kategoriya bo\u2018yicha filtr', () async {
      final cpus = await products.getByCategory('cpu');
      expect(cpus, isNotEmpty);
      expect(cpus.every((p) => p.categoryId == 'cpu'), isTrue);
    });

    test('narx bo\u2018yicha saralash', () async {
      final asc = await products.query(
          const ProductFilter(sort: SortOption.priceAsc));
      for (var i = 1; i < asc.length; i++) {
        expect(asc[i].price, greaterThanOrEqualTo(asc[i - 1].price));
      }

      final desc = await products.query(
          const ProductFilter(sort: SortOption.priceDesc));
      for (var i = 1; i < desc.length; i++) {
        expect(desc[i].price, lessThanOrEqualTo(desc[i - 1].price));
      }
    });

    test('narx oralig\u2018i filtri', () async {
      final result = await products.query(
        const ProductFilter(minPrice: 1000000, maxPrice: 3000000),
      );
      expect(result, isNotEmpty);
      expect(
        result.every((p) => p.price >= 1000000 && p.price <= 3000000),
        isTrue,
      );
    });

    test('brend filtri', () async {
      final result =
          await products.query(const ProductFilter(brands: {'Apple'}));
      expect(result, isNotEmpty);
      expect(result.every((p) => p.brand == 'Apple'), isTrue);
    });

    test('faqat chegirmadagilar filtri', () async {
      final result =
          await products.query(const ProductFilter(onlyDiscount: true));
      expect(result, isNotEmpty);
      expect(result.every((p) => p.hasDiscount), isTrue);
    });

    test('bir nechta filtr birga ishlaydi', () async {
      final result = await products.query(const ProductFilter(
        categoryId: 'phones',
        minRating: 4.5,
        onlyInStock: true,
      ));
      expect(
        result.every((p) =>
            p.categoryId == 'phones' && p.rating >= 4.5 && p.stock > 0),
        isTrue,
      );
    });

    test('brendlar ro\u2018yxati takrorlanmaydi', () async {
      final brands = await products.brands();
      expect(brands.length, brands.toSet().length);
      expect(brands, contains('Apple'));
    });

    test('narx oralig\u2018i to\u2018g\u2018ri hisoblanadi', () async {
      final (min, max) = await products.priceRange(categoryId: 'cpu');
      final cpus = await products.getByCategory('cpu');
      expect(min, cpus.map((p) => p.price).reduce((a, b) => a < b ? a : b));
      expect(max, cpus.map((p) => p.price).reduce((a, b) => a > b ? a : b));
    });

    test('o\u2018xshash mahsulotlar bir kategoriyadan', () async {
      final cpu = (await products.getByCategory('cpu')).first;
      final similar = await products.similar(cpu, limit: 5);
      expect(similar, isNotEmpty);
      expect(similar.every((p) => p.categoryId == 'cpu'), isTrue);
      expect(similar.any((p) => p.id == cpu.id), isFalse);
    });

    test('getByIds tartibni saqlaydi', () async {
      final all = await products.getAll();
      final ids = [all[3].id, all[1].id, all[7].id];
      final found = await products.getByIds(ids);
      expect(found.map((p) => p.id).toList(), ids);
    });
  });

  group('CartRepository', () {
    late String productId;

    setUp(() async {
      productId = (await products.getAll()).first.id;
    });

    test('yangi savat bo\u2018sh', () async {
      final result = await cart.getCart();
      expect(result.isEmpty, isTrue);
      expect(result.count, 0);
      expect(result.subtotal, 0);
    });

    test('mahsulot qo\u2018shiladi', () async {
      await cart.add(productId);
      final result = await cart.getCart();
      expect(result.count, 1);
      expect(result.lines.first.product.id, productId);
    });

    test('takroriy qo\u2018shish miqdorni oshiradi', () async {
      await cart.add(productId);
      await cart.add(productId, quantity: 2);
      final result = await cart.getCart();
      expect(result.lines.length, 1);
      expect(result.quantityOf(productId), 3);
    });

    test('miqdorni 0 ga tenglash mahsulotni o\u2018chiradi', () async {
      await cart.add(productId);
      await cart.setQuantity(productId, 0);
      expect((await cart.getCart()).isEmpty, isTrue);
    });

    test('miqdor ombordan oshmaydi', () async {
      final product = await products.getById(productId);
      await cart.setQuantity(productId, product!.stock + 100);
      expect((await cart.getCart()).quantityOf(productId), product.stock);
    });

    test('summa to\u2018g\u2018ri hisoblanadi', () async {
      final product = (await products.getAll()).first;
      await cart.add(product.id, quantity: 3);
      final result = await cart.getCart();
      expect(result.subtotal, product.price * 3);
    });

    test('savat tozalanadi', () async {
      await cart.add(productId);
      await cart.clear();
      expect((await cart.getCart()).isEmpty, isTrue);
    });

    test('yetkazish narxi 5 mln dan yuqorida bepul', () async {
      final expensive = (await products.getAll())
          .firstWhere((p) => p.price > 5000000 && p.stock > 0);
      await cart.add(expensive.id);
      final result = await cart.getCart();
      expect(result.deliveryFee(DeliveryType.courier), 0);
    });

    test('arzon savatda yetkazish pullik', () async {
      final cheap = (await products.getAll())
          .firstWhere((p) => p.price < 500000 && p.stock > 0);
      await cart.add(cheap.id);
      final result = await cart.getCart();
      expect(result.deliveryFee(DeliveryType.courier), greaterThan(0));
      expect(result.deliveryFee(DeliveryType.pickup), 0);
    });
  });

  group('OrderRepository', () {
    test('savatdan buyurtma yaratiladi', () async {
      final product = (await products.getAll()).firstWhere((p) => p.stock > 2);
      await cart.add(product.id, quantity: 2);

      final order = await orders.createFromCart(
        cart: await cart.getCart(),
        deliveryType: DeliveryType.courier,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Jasur Aliyev',
        phone: '+998901234567',
        address: 'Toshkent, Chilonzor 5',
      );

      expect(order.items.length, 1);
      expect(order.itemCount, 2);
      expect(order.status, OrderStatus.pending);
      expect(order.subtotal, product.price * 2);
      expect(order.number, startsWith('TB-'));
    });

    test('buyurtmadan keyin savat bo\u2018shaydi', () async {
      final product = (await products.getAll()).firstWhere((p) => p.stock > 0);
      await cart.add(product.id);
      await orders.createFromCart(
        cart: await cart.getCart(),
        deliveryType: DeliveryType.pickup,
        paymentMethod: PaymentMethod.click,
        customerName: 'Test',
        phone: '+998901234567',
        address: 'Do\u2018kon',
      );
      expect((await cart.getCart()).isEmpty, isTrue);
    });

    test('ombordagi miqdor kamayadi', () async {
      final product = (await products.getAll()).firstWhere((p) => p.stock > 3);
      final before = product.stock;
      await cart.add(product.id, quantity: 2);
      await orders.createFromCart(
        cart: await cart.getCart(),
        deliveryType: DeliveryType.courier,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Test',
        phone: '+998901234567',
        address: 'Toshkent',
      );
      final after = await products.getById(product.id);
      expect(after!.stock, before - 2);
    });

    test('bo\u2018sh savatdan buyurtma bermaydi', () async {
      expect(
        () => orders.createFromCart(
          cart: Cart.empty,
          deliveryType: DeliveryType.courier,
          paymentMethod: PaymentMethod.cash,
          customerName: 'Test',
          phone: '+998901234567',
          address: 'Toshkent',
        ),
        throwsStateError,
      );
    });

    test('bekor qilinganda ombor tiklanadi', () async {
      final product = (await products.getAll()).firstWhere((p) => p.stock > 3);
      final before = product.stock;
      await cart.add(product.id, quantity: 2);
      final order = await orders.createFromCart(
        cart: await cart.getCart(),
        deliveryType: DeliveryType.courier,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Test',
        phone: '+998901234567',
        address: 'Toshkent',
      );

      await orders.cancel(order.id);

      final updated = await orders.getById(order.id);
      expect(updated!.status, OrderStatus.cancelled);
      expect((await products.getById(product.id))!.stock, before);
    });

    test('yetkazilgan buyurtmani bekor qilib bo\u2018lmaydi', () async {
      final product = (await products.getAll()).firstWhere((p) => p.stock > 0);
      await cart.add(product.id);
      final order = await orders.createFromCart(
        cart: await cart.getCart(),
        deliveryType: DeliveryType.courier,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Test',
        phone: '+998901234567',
        address: 'Toshkent',
      );
      await orders.updateStatus(order.id, OrderStatus.delivered);
      expect(() => orders.cancel(order.id), throwsStateError);
    });

    test('buyurtmalar yangisidan boshlab tartiblanadi', () async {
      final all = await products.getAll();
      for (var i = 0; i < 2; i++) {
        await cart.add(all[i].id);
        await orders.createFromCart(
          cart: await cart.getCart(),
          deliveryType: DeliveryType.courier,
          paymentMethod: PaymentMethod.cash,
          customerName: 'Test',
          phone: '+998901234567',
          address: 'Toshkent',
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final list = await orders.getAll();
      expect(list.length, 2);
      expect(
        list.first.createdAt.isAfter(list.last.createdAt) ||
            list.first.createdAt.isAtSameMomentAs(list.last.createdAt),
        isTrue,
      );
    });
  });

  group('FavoritesRepository', () {
    test('qo\u2018shish va olib tashlash', () async {
      final favorites = LocalFavoritesRepository(db);
      final id = (await products.getAll()).first.id;

      expect(await favorites.contains(id), isFalse);
      expect(await favorites.toggle(id), isTrue);
      expect(await favorites.contains(id), isTrue);
      expect(await favorites.ids(), contains(id));

      expect(await favorites.toggle(id), isFalse);
      expect(await favorites.ids(), isEmpty);
    });
  });

  group('UserRepository', () {
    test('profil saqlanadi va o\u2018qiladi', () async {
      final users = LocalUserRepository(db);
      final initial = await users.getCurrent();
      expect(initial.name, isEmpty);

      await users.save(initial.copyWith(
        name: 'Dilnoza Karimova',
        phone: '+998901112233',
      ));

      final loaded = await users.getCurrent();
      expect(loaded.name, 'Dilnoza Karimova');
      expect(loaded.initials, 'DK');
      expect(loaded.isFilled, isTrue);
    });

    test('sozlamalar saqlanadi', () async {
      final users = LocalUserRepository(db);
      expect(await users.getSetting('yoq'), isNull);
      await users.setSetting('ai_api_key', 'sk-test');
      expect(await users.getSetting('ai_api_key'), 'sk-test');
    });
  });

  group('HistoryRepository', () {
    test('qidiruv tarixi takrorlanmaydi', () async {
      final history = LocalHistoryRepository(db);
      await history.addSearch('noutbuk');
      await history.addSearch('noutbuk');
      await history.addSearch('telefon');
      final recent = await history.recentSearches();
      expect(recent.length, 2);
      expect(recent.first, 'telefon');
    });

    test('ko\u2018rilgan mahsulotlar saqlanadi', () async {
      final history = LocalHistoryRepository(db);
      final all = await products.getAll();
      await history.addViewed(all[0].id);
      await history.addViewed(all[1].id);
      final viewed = await history.recentlyViewed();
      expect(viewed.first, all[1].id);
    });
  });

  group('ReviewRepository', () {
    test('sharh qo\u2018shiladi va o\u2018qiladi', () async {
      final reviews = LocalReviewRepository(db);
      final id = (await products.getAll()).first.id;
      final before = (await reviews.forProduct(id)).length;

      await reviews.add(Review(
        id: 'test-review',
        productId: id,
        author: 'Sardor',
        rating: 5,
        text: 'Ajoyib mahsulot',
        createdAt: DateTime.now(),
      ));

      final after = await reviews.forProduct(id);
      expect(after.length, before + 1);
      expect(after.first.author, 'Sardor');
    });
  });

  group('PcBuildRepository', () {
    test('yig\u2018ilma saqlanadi va o\u2018chiriladi', () async {
      final builds = LocalPcBuildRepository(db);
      await builds.save(PcBuild(
        id: 'build-1',
        name: 'Gaming PC',
        createdAt: DateTime.now(),
        productIds: const {'cpu': 'cpu-1', 'gpu': 'gpu-1'},
      ));

      final all = await builds.getAll();
      expect(all.length, 1);
      expect(all.first.productIds['cpu'], 'cpu-1');

      await builds.delete('build-1');
      expect(await builds.getAll(), isEmpty);
    });
  });

  group('ChatRepository', () {
    test('xabarlar tartib bilan saqlanadi', () async {
      final chat = LocalChatRepository(db);
      await chat.add(ChatMessage(
        id: 0,
        role: 'user',
        text: 'Salom',
        createdAt: DateTime.now(),
      ));
      await chat.add(ChatMessage(
        id: 0,
        role: 'ai',
        text: 'Assalomu alaykum',
        createdAt: DateTime.now(),
        productIds: const ['cpu-1'],
      ));

      final history = await chat.history();
      expect(history.length, 2);
      expect(history.first.isUser, isTrue);
      expect(history.last.productIds, ['cpu-1']);

      await chat.clear();
      expect(await chat.history(), isEmpty);
    });
  });
}
