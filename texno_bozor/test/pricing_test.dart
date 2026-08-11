import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/core/constants/app_constants.dart';
import 'package:texno_bozor/core/utils/format.dart';
import 'package:texno_bozor/core/utils/pricing.dart';
import 'package:texno_bozor/core/utils/specs.dart';
import 'package:texno_bozor/data/models/enums.dart';

void main() {
  group('Narx hisob-kitobi', () {
    test('bo\u2018sh savat: hamma qiymat nol', () {
      final totals = calcOrderTotals(
        lines: const [],
        delivery: DeliveryMethod.standard,
      );
      expect(totals.subtotal, 0);
      expect(totals.discount, 0);
      expect(totals.deliveryFee, 0);
      expect(totals.total, 0);
    });

    test('chegirma eski narx bo\u2018yicha hisoblanadi', () {
      final totals = calcOrderTotals(
        lines: const [
          (price: 1000000, oldPrice: 1200000, qty: 2),
          (price: 500000, oldPrice: null, qty: 1),
        ],
        delivery: DeliveryMethod.standard,
      );
      expect(totals.subtotal, 2500000);
      expect(totals.discount, 400000);
      expect(totals.deliveryFee, AppConstants.standardDeliveryFee);
      expect(totals.total, 2500000 + AppConstants.standardDeliveryFee);
    });

    test('express yetkazish qimmatroq', () {
      final express = calcOrderTotals(
        lines: const [(price: 1000000, oldPrice: null, qty: 1)],
        delivery: DeliveryMethod.express,
      );
      expect(express.deliveryFee, AppConstants.expressDeliveryFee);
    });

    test('katta summada yetkazish bepul', () {
      final totals = calcOrderTotals(
        lines: [
          (price: AppConstants.freeDeliveryFrom, oldPrice: null, qty: 1),
        ],
        delivery: DeliveryMethod.express,
      );
      expect(totals.deliveryFee, 0);
      expect(totals.isFreeDelivery, isTrue);
      expect(totals.amountToFreeDelivery, 0);
      expect(totals.total, AppConstants.freeDeliveryFrom);
    });

    test('bepul yetkazishgacha qolgan summa', () {
      final totals = calcOrderTotals(
        lines: const [(price: 1000000, oldPrice: null, qty: 1)],
        delivery: DeliveryMethod.standard,
      );
      expect(
        totals.amountToFreeDelivery,
        AppConstants.freeDeliveryFrom - 1000000,
      );
    });

    test('eski narx pastroq bo\u2018lsa chegirma yo\u2018q', () {
      final totals = calcOrderTotals(
        lines: const [(price: 1000000, oldPrice: 900000, qty: 1)],
        delivery: DeliveryMethod.standard,
      );
      expect(totals.discount, 0);
    });
  });

  group('Formatlash', () {
    test('summa uch xonalab ajratiladi', () {
      expect(formatSum(1234500).replaceAll('\u2009', ' '), '1 234 500 so\u2018m');
      expect(formatSum(0), '0 so\u2018m');
    });

    test('chegirma foizi', () {
      expect(discountPercent(800000, 1000000), 20);
      expect(discountPercent(1000000, null), 0);
      expect(discountPercent(1000000, 900000), 0);
    });

    test('sana formati', () {
      expect(formatDate(DateTime(2026, 8, 11)), '11.08.2026');
      expect(
        formatDateTime(DateTime(2026, 8, 11, 9, 5)),
        '11.08.2026 09:05',
      );
    });
  });

  group('Texnik xususiyatlar', () {
    test('JSON parse va encode', () {
      final specs = parseSpecs('{"socket":"AM5","tdp":"120 W"}');
      expect(specs['socket'], 'AM5');
      expect(specInt(specs, 'tdp'), 120);
      expect(parseSpecs(encodeSpecs(specs))['socket'], 'AM5');
    });

    test('buzuq JSON ilovani yiqitmaydi', () {
      expect(parseSpecs('bu json emas'), isEmpty);
      expect(parseSpecs(''), isEmpty);
    });
  });
}
