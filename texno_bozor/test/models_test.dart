import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/models/models.dart';

void main() {
  group('Product', () {
    const product = Product(
      id: 'p1',
      name: 'Test',
      brand: 'Brand',
      categoryId: 'cpu',
      price: 800000,
      oldPrice: 1000000,
      stock: 3,
      specs: {'tdp': '105 W', 'socket': 'AM5'},
    );

    test('chegirma foizi', () {
      expect(product.hasDiscount, isTrue);
      expect(product.discountPercent, 20);
    });

    test('chegirmasiz mahsulot', () {
      const plain = Product(
        id: 'p2',
        name: 'Test',
        brand: 'B',
        categoryId: 'cpu',
        price: 500000,
      );
      expect(plain.hasDiscount, isFalse);
      expect(plain.discountPercent, 0);
    });

    test('ombor holati', () {
      expect(product.inStock, isTrue);
      expect(product.copyWith(stock: 0).inStock, isFalse);
    });

    test('specInt sonni ajratadi', () {
      expect(product.specInt('tdp'), 105);
      expect(product.specInt('yoq', fallback: 7), 7);
      expect(product.spec('socket'), 'AM5');
    });

    test('isNew 30 kun ichida', () {
      final fresh = Product(
        id: 'p3',
        name: 'X',
        brand: 'B',
        categoryId: 'cpu',
        price: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      final old = Product(
        id: 'p4',
        name: 'X',
        brand: 'B',
        categoryId: 'cpu',
        price: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      expect(fresh.isNew, isTrue);
      expect(old.isNew, isFalse);
    });

    test('map orqali aylanish (round-trip)', () {
      final restored = Product.fromMap(product.toMap());
      expect(restored.id, product.id);
      expect(restored.price, product.price);
      expect(restored.specs['socket'], 'AM5');
    });
  });

  group('Cart', () {
    const a = Product(
      id: 'a',
      name: 'A',
      brand: 'B',
      categoryId: 'c',
      price: 1000000,
      stock: 5,
    );
    const b = Product(
      id: 'b',
      name: 'B',
      brand: 'B',
      categoryId: 'c',
      price: 2000000,
      stock: 5,
    );

    test('bo\u2018sh savat', () {
      expect(Cart.empty.isEmpty, isTrue);
      expect(Cart.empty.count, 0);
      expect(Cart.empty.subtotal, 0);
    });

    test('summa va miqdor', () {
      const cart = Cart([
        CartLine(product: a, quantity: 2),
        CartLine(product: b, quantity: 1),
      ]);
      expect(cart.count, 3);
      expect(cart.subtotal, 4000000);
      expect(cart.quantityOf('a'), 2);
      expect(cart.quantityOf('yoq'), 0);
    });

    test('yetkazish narxlari', () {
      const small = Cart([CartLine(product: a, quantity: 1)]);
      expect(small.deliveryFee(DeliveryType.courier), 25000);
      expect(small.deliveryFee(DeliveryType.express), 45000);
      expect(small.deliveryFee(DeliveryType.pickup), 0);

      const big = Cart([CartLine(product: b, quantity: 3)]);
      expect(big.subtotal, 6000000);
      expect(big.deliveryFee(DeliveryType.courier), 0);
    });

    test('jami summa yetkazish bilan', () {
      const cart = Cart([CartLine(product: a, quantity: 1)]);
      expect(cart.total(DeliveryType.courier), 1025000);
      expect(cart.total(DeliveryType.pickup), 1000000);
    });
  });

  group('Order', () {
    test('raqam formati', () {
      final order = Order(
        id: 'ord-1754924400123',
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        items: const [
          OrderItem(productId: 'a', name: 'A', price: 100, quantity: 2),
        ],
        subtotal: 200,
        deliveryFee: 25000,
        deliveryType: DeliveryType.courier,
        paymentMethod: PaymentMethod.cash,
        customerName: 'Test',
        phone: '+998901234567',
        address: 'Toshkent',
      );
      expect(order.number, 'TB-0123');
      expect(order.total, 25200);
      expect(order.itemCount, 2);
    });

    test('status yakuniyligi', () {
      expect(OrderStatus.delivered.isFinal, isTrue);
      expect(OrderStatus.cancelled.isFinal, isTrue);
      expect(OrderStatus.shipping.isFinal, isFalse);
    });

    test('enum nomdan tiklanadi', () {
      expect(OrderStatus.fromName('shipping'), OrderStatus.shipping);
      expect(OrderStatus.fromName('yoq'), OrderStatus.pending);
      expect(DeliveryType.fromName('pickup'), DeliveryType.pickup);
      expect(PaymentMethod.fromName('payme'), PaymentMethod.payme);
    });
  });

  group('AppUser', () {
    test('bosh harflar', () {
      expect(const AppUser(id: 'me', name: 'Jasur Aliyev').initials, 'JA');
      expect(const AppUser(id: 'me', name: 'Jasur').initials, 'JA');
      expect(const AppUser(id: 'me').initials, 'TB');
    });

    test('to\u2018liqlik tekshiruvi', () {
      expect(const AppUser(id: 'me').isFilled, isFalse);
      expect(
        const AppUser(id: 'me', name: 'A', phone: '+998901234567').isFilled,
        isTrue,
      );
    });
  });

  group('ProductFilter', () {
    test('faol filtrlarni sanaydi', () {
      const filter = ProductFilter(
        brands: {'Apple'},
        minPrice: 1000,
        onlyInStock: true,
      );
      expect(filter.hasActiveFilters, isTrue);
      expect(filter.activeCount, 3);
    });

    test('tozalash kategoriyani saqlaydi', () {
      const filter = ProductFilter(
        categoryId: 'cpu',
        brands: {'AMD'},
        sort: SortOption.priceAsc,
      );
      final cleared = filter.cleared();
      expect(cleared.categoryId, 'cpu');
      expect(cleared.sort, SortOption.priceAsc);
      expect(cleared.brands, isEmpty);
      expect(cleared.hasActiveFilters, isFalse);
    });

    test('copyWith kategoriya o\u2018chirish', () {
      const filter = ProductFilter(categoryId: 'cpu');
      expect(filter.copyWith(clearCategory: true).categoryId, isNull);
      expect(filter.copyWith(categoryId: 'gpu').categoryId, 'gpu');
    });
  });
}
