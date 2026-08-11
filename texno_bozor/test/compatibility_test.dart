import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/core/constants/app_constants.dart';
import 'package:texno_bozor/core/utils/specs.dart';
import 'package:texno_bozor/data/database/app_database.dart';
import 'package:texno_bozor/data/models/app_models.dart';
import 'package:texno_bozor/data/models/enums.dart';
import 'package:texno_bozor/features/pc_builder/compatibility.dart';

/// Test uchun soxta mahsulot yaratish.
Product mkPart(
  String id,
  String name,
  Map<String, String> specs, {
  int price = 1000000,
}) {
  return Product(
    id: id,
    name: name,
    brand: 'TestBrand',
    categoryId: 'cat_test',
    price: price,
    rating: 4.5,
    reviewsCount: 10,
    stock: 5,
    warranty: '12 oy',
    description: '',
    specsJson: encodeSpecs(specs),
    emoji: '\u{1F4E6}',
    popularity: 1,
    createdAt: 0,
    isTop: 0,
  );
}

Map<PcPartType, Product?> emptyBuild() => {
      for (final t in PcPartType.values) t: null,
    };

CompatCheck? findCheck(List<CompatCheck> checks, String needle) {
  for (final c in checks) {
    if (c.title.contains(needle)) return c;
  }
  return null;
}

void main() {
  group('PC Builder — tanlanmagan komponentlar', () {
    test('bo\u2018sh yig\u2018ilmada barcha komponentlar yetishmaydi', () {
      final checks = checkBuild(emptyBuild());
      final missing = findCheck(checks, 'Tanlanmagan');
      expect(missing, isNotNull);
      expect(missing!.ok, isFalse);
      expect(missing.details, contains('Protsessor'));
      expect(isBuildCompatible(emptyBuild()), isFalse);
    });
  });

  group('1. Socket mosligi', () {
    test('bir xil socket — mos', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'Core i5', {'socket': 'LGA1700'})
        ..[PcPartType.motherboard] =
            mkPart('mb', 'B760M', {'socket': 'LGA1700'});
      final check = findCheck(checkBuild(parts), 'Socket mos: LGA1700');
      expect(check, isNotNull);
      expect(check!.ok, isTrue);
    });

    test('turli socket — xato', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'Ryzen 7', {'socket': 'AM5'})
        ..[PcPartType.motherboard] =
            mkPart('mb', 'B760M', {'socket': 'LGA1700'});
      final check = findCheck(checkBuild(parts), 'Socket mos emas');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
      expect(check.details, contains('AM5'));
      expect(check.details, contains('LGA1700'));
    });
  });

  group('2. RAM turi vs ona plata', () {
    test('DDR5 + DDR5 — mos', () {
      final parts = emptyBuild()
        ..[PcPartType.ram] = mkPart('ram', 'Kingston 32GB', {'ram_type': 'DDR5'})
        ..[PcPartType.motherboard] = mkPart('mb', 'B650', {'ram_type': 'DDR5'});
      final check = findCheck(checkBuild(parts), 'RAM mos: DDR5');
      expect(check?.ok, isTrue);
    });

    test('DDR4 xotira DDR5 plataga mos emas', () {
      final parts = emptyBuild()
        ..[PcPartType.ram] = mkPart('ram', 'Kingston 16GB', {'ram_type': 'DDR4'})
        ..[PcPartType.motherboard] = mkPart('mb', 'B650', {'ram_type': 'DDR5'});
      final check = findCheck(checkBuild(parts), 'RAM mos emas');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
    });
  });

  group('3. CPU RAM qo\u2018llab-quvvatlashi', () {
    test('CPU faqat DDR4 qo\u2018llasa, DDR5 plata xato beradi', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'Core i5-11400', {
          'socket': 'LGA1200',
          'ram_type': 'DDR4',
        })
        ..[PcPartType.motherboard] = mkPart('mb', 'Z790', {
          'socket': 'LGA1200',
          'ram_type': 'DDR5',
        });
      final check = findCheck(checkBuild(parts), 'qo\u2018llamaydi');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
    });

    test('CPU DDR4/DDR5 ikkalasini qo\u2018llasa — xato yo\u2018q', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'Core i5-12400', {
          'socket': 'LGA1700',
          'ram_type': 'DDR4/DDR5',
        })
        ..[PcPartType.motherboard] = mkPart('mb', 'B760', {
          'socket': 'LGA1700',
          'ram_type': 'DDR5',
        });
      expect(findCheck(checkBuild(parts), 'qo\u2018llamaydi'), isNull);
    });
  });

  group('4. PSU quvvati', () {
    test('yetarli quvvat — mos', () {
      final needed = 125 + 220 + AppConstants.systemBaseWatt;
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'i7', {'tdp': '125'})
        ..[PcPartType.gpu] = mkPart('gpu', 'RTX 4070', {'tdp': '220'})
        ..[PcPartType.psu] = mkPart('psu', '750W', {'psu_watt': '750'});
      final check = findCheck(checkBuild(parts), 'Quvvat yetarli');
      expect(check, isNotNull);
      expect(check!.ok, isTrue);
      expect(750, greaterThanOrEqualTo(needed));
    });

    test('kuchsiz blok — xato', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'i9', {'tdp': '250'})
        ..[PcPartType.gpu] = mkPart('gpu', 'RTX 4090', {'tdp': '450'})
        ..[PcPartType.psu] = mkPart('psu', '450W', {'psu_watt': '450'});
      final check = findCheck(checkBuild(parts), 'kuchsiz');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
      final needed = 250 + 450 + AppConstants.systemBaseWatt;
      expect(check.details, contains('$needed'));
    });

    test('CPU/GPU tanlanmasa standart qiymatlar ishlatiladi', () {
      final parts = emptyBuild()
        ..[PcPartType.psu] = mkPart('psu', '400W', {'psu_watt': '400'});
      final needed = 95 + 150 + AppConstants.systemBaseWatt;
      final check = findCheck(checkBuild(parts), 'Quvvat');
      expect(check, isNotNull);
      expect(check!.ok, 400 >= needed);
    });
  });

  group('5. GPU uzunligi vs korpus', () {
    test('sig\u2018adigan videokarta', () {
      final parts = emptyBuild()
        ..[PcPartType.gpu] = mkPart('gpu', 'RTX 4060', {'gpu_length': '242'})
        ..[PcPartType.caseUnit] =
            mkPart('case', 'Deepcool', {'max_gpu_length': '360'});
      expect(findCheck(checkBuild(parts), 'sig\u2018adi')?.ok, isTrue);
    });

    test('sig\u2018maydigan videokarta', () {
      final parts = emptyBuild()
        ..[PcPartType.gpu] = mkPart('gpu', 'RTX 4090', {'gpu_length': '358'})
        ..[PcPartType.caseUnit] =
            mkPart('case', 'Mini korpus', {'max_gpu_length': '300'});
      final check = findCheck(checkBuild(parts), 'Videokarta korpusga sig\u2018maydi');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
    });
  });

  group('6. Sovutgich balandligi vs korpus', () {
    test('past sovutgich sig\u2018adi', () {
      final parts = emptyBuild()
        ..[PcPartType.cooler] =
            mkPart('cooler', 'AK400', {'cooler_height': '155'})
        ..[PcPartType.caseUnit] = mkPart('case', 'Midi', {'max_cooler': '170'});
      final check = findCheck(checkBuild(parts), 'Sovutgich korpusga sig\u2018adi');
      expect(check?.ok, isTrue);
    });

    test('baland sovutgich sig\u2018maydi', () {
      final parts = emptyBuild()
        ..[PcPartType.cooler] =
            mkPart('cooler', 'NH-D15', {'cooler_height': '165'})
        ..[PcPartType.caseUnit] = mkPart('case', 'Slim', {'max_cooler': '120'});
      final check =
          findCheck(checkBuild(parts), 'Sovutgich korpusga sig\u2018maydi');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
    });
  });

  group('7. Sovutgich quvvati vs CPU TDP', () {
    test('yetarli sovutgich', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'i5', {'tdp': '125'})
        ..[PcPartType.cooler] = mkPart('cooler', 'AK620', {'cooler_tdp': '260'});
      expect(findCheck(checkBuild(parts), 'sovuta oladi')?.ok, isTrue);
    });

    test('kuchsiz sovutgich', () {
      final parts = emptyBuild()
        ..[PcPartType.cpu] = mkPart('cpu', 'i9', {'tdp': '250'})
        ..[PcPartType.cooler] = mkPart('cooler', 'Box', {'cooler_tdp': '95'});
      final check = findCheck(checkBuild(parts), 'Sovutgich kuchsiz');
      expect(check, isNotNull);
      expect(check!.ok, isFalse);
    });
  });

  group('To\u2018liq yig\u2018ilma', () {
    Map<PcPartType, Product?> goodBuild() => {
          PcPartType.cpu: mkPart('cpu', 'Ryzen 7 7700X', {
            'socket': 'AM5',
            'ram_type': 'DDR5',
            'tdp': '105',
          }, price: 4500000),
          PcPartType.motherboard: mkPart('mb', 'B650M', {
            'socket': 'AM5',
            'ram_type': 'DDR5',
          }, price: 2200000),
          PcPartType.ram:
              mkPart('ram', 'DDR5 32GB', {'ram_type': 'DDR5'}, price: 1500000),
          PcPartType.gpu: mkPart('gpu', 'RTX 4070', {
            'tdp': '200',
            'gpu_length': '244',
          }, price: 8000000),
          PcPartType.ssd: mkPart('ssd', 'NVMe 1TB', {}, price: 900000),
          PcPartType.hdd: mkPart('hdd', 'HDD 2TB', {}, price: 700000),
          PcPartType.psu:
              mkPart('psu', '750W Gold', {'psu_watt': '750'}, price: 1100000),
          PcPartType.caseUnit: mkPart('case', 'Midi Tower', {
            'max_gpu_length': '360',
            'max_cooler': '170',
          }, price: 800000),
          PcPartType.cooler: mkPart('cooler', 'AK620', {
            'cooler_height': '160',
            'cooler_tdp': '260',
          }, price: 500000),
        };

    test('mos yig\u2018ilma barcha tekshiruvlardan o\u2018tadi', () {
      final checks = checkBuild(goodBuild());
      expect(checks.every((c) => c.ok), isTrue,
          reason: checks.where((c) => !c.ok).map((c) => c.title).join('; '));
      expect(isBuildCompatible(goodBuild()), isTrue);
    });

    test('umumiy narx to\u2018g\u2018ri qo\u2018shiladi', () {
      expect(buildTotalPrice(goodBuild()), 20200000);
      expect(buildTotalPrice(emptyBuild()), 0);
    });

    test('bitta noto\u2018g\u2018ri komponent yig\u2018ilmani buzadi', () {
      final parts = goodBuild()
        ..[PcPartType.motherboard] = mkPart('mb', 'B760M', {
          'socket': 'LGA1700',
          'ram_type': 'DDR5',
        });
      expect(isBuildCompatible(parts), isFalse);
    });
  });
}
