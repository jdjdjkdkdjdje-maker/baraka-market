import 'package:flutter_test/flutter_test.dart';
import 'package:texno_bozor/data/models/models.dart';
import 'package:texno_bozor/features/pc_builder/compatibility.dart';

Product part({
  required String id,
  required String category,
  Map<String, String> specs = const {},
  int price = 1000000,
  int stock = 5,
}) {
  return Product(
    id: id,
    name: id,
    brand: 'Test',
    categoryId: category,
    price: price,
    stock: stock,
    specs: specs,
  );
}

void main() {
  final ryzenAm5 = part(
    id: 'cpu-am5',
    category: 'cpu',
    specs: const {
      'socket': 'AM5',
      'tdp': '105',
      'xotira': 'DDR5',
      'grafika': 'bor',
    },
  );
  final intelLga = part(
    id: 'cpu-lga',
    category: 'cpu',
    specs: const {
      'socket': 'LGA1700',
      'tdp': '125',
      'xotira': 'DDR4/DDR5',
      'grafika': 'yo\u2018q',
    },
  );
  final mbAm5 = part(
    id: 'mb-am5',
    category: 'motherboard',
    specs: const {
      'socket': 'AM5',
      'xotira': 'DDR5',
      'form': 'ATX',
    },
  );
  final mbAm4 = part(
    id: 'mb-am4',
    category: 'motherboard',
    specs: const {
      'socket': 'AM4',
      'xotira': 'DDR4',
      'form': 'ATX',
    },
  );
  final ramDdr5 = part(
    id: 'ram-ddr5',
    category: 'ram',
    specs: const {'xotira': 'DDR5', 'hajm': '32'},
  );
  final ramDdr4 = part(
    id: 'ram-ddr4',
    category: 'ram',
    specs: const {'xotira': 'DDR4', 'hajm': '16'},
  );
  final gpuBig = part(
    id: 'gpu-big',
    category: 'gpu',
    specs: const {'tdp': '320', 'uzunlik': '336', 'quvvat': '850'},
  );
  final gpuSmall = part(
    id: 'gpu-small',
    category: 'gpu',
    specs: const {'tdp': '115', 'uzunlik': '242', 'quvvat': '550'},
  );
  final psu650 = part(
    id: 'psu-650',
    category: 'psu',
    specs: const {'quvvat': '650', 'uzunlik': '140'},
  );
  final psu1000 = part(
    id: 'psu-1000',
    category: 'psu',
    specs: const {'quvvat': '1000', 'uzunlik': '150'},
  );
  final caseAtx = part(
    id: 'case-atx',
    category: 'case',
    specs: const {
      'form': 'ATX',
      'gpu_uzunlik': '392',
      'kuler_balandlik': '180',
      'psu_uzunlik': '210',
    },
  );
  final caseSmall = part(
    id: 'case-matx',
    category: 'case',
    specs: const {
      'form': 'mATX',
      'gpu_uzunlik': '260',
      'kuler_balandlik': '150',
      'psu_uzunlik': '160',
    },
  );
  final coolerAm5 = part(
    id: 'cooler-am5',
    category: 'cooler',
    specs: const {
      'tip': 'Havo',
      'balandlik': '160',
      'tdp': '260',
      'socket': 'AM5, AM4, LGA1700',
    },
  );
  final coolerWeak = part(
    id: 'cooler-weak',
    category: 'cooler',
    specs: const {
      'tip': 'Havo',
      'balandlik': '159',
      'tdp': '95',
      'socket': 'AM4, LGA1700',
    },
  );
  final ssd = part(
    id: 'ssd-1',
    category: 'ssd',
    specs: const {'hajm': '1 TB'},
  );

  group('Soket mosligi', () {
    test('mos soket xato bermaydi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.motherboard: mbAm5,
      });
      expect(report.errors, isEmpty);
      expect(
        report.issues.any((i) => i.level == IssueLevel.info),
        isTrue,
      );
    });

    test('nomos soket xato beradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.motherboard: mbAm4,
      });
      expect(report.errors, isNotEmpty);
      expect(report.errors.first.message, contains('soket'));
    });
  });

  group('Xotira mosligi', () {
    test('DDR5 plata + DDR4 modul xato', () {
      final report = CompatibilityChecker.check({
        PcSlot.motherboard: mbAm5,
        PcSlot.ram: ramDdr4,
      });
      expect(report.errors, isNotEmpty);
    });

    test('DDR5 plata + DDR5 modul to\u2018g\u2018ri', () {
      final report = CompatibilityChecker.check({
        PcSlot.motherboard: mbAm5,
        PcSlot.ram: ramDdr5,
      });
      expect(report.errors, isEmpty);
    });

    test('protsessor xotira turi tekshiriladi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.ram: ramDdr4,
      });
      expect(report.errors, isNotEmpty);
    });
  });

  group('Korpus o\u2018lchamlari', () {
    test('uzun videokarta kichik korpusga sig\u2018maydi', () {
      final report = CompatibilityChecker.check({
        PcSlot.pcCase: caseSmall,
        PcSlot.gpu: gpuBig,
      });
      expect(report.errors.any((e) => e.message.contains('Videokarta')), isTrue);
    });

    test('kichik videokarta sig\u2018adi', () {
      final report = CompatibilityChecker.check({
        PcSlot.pcCase: caseSmall,
        PcSlot.gpu: gpuSmall,
      });
      expect(report.errors, isEmpty);
    });

    test('ATX plata mATX korpusga sig\u2018maydi', () {
      final report = CompatibilityChecker.check({
        PcSlot.pcCase: caseSmall,
        PcSlot.motherboard: mbAm5,
      });
      expect(report.errors.any((e) => e.message.contains('sig')), isTrue);
    });

    test('baland sovutgich past korpusga sig\u2018maydi', () {
      final report = CompatibilityChecker.check({
        PcSlot.pcCase: caseSmall,
        PcSlot.cooler: coolerAm5,
      });
      expect(report.errors.any((e) => e.message.contains('Sovutgich')), isTrue);
    });
  });

  group('Sovutgich', () {
    test('qo\u2018llanmaydigan soket xato beradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.cooler: coolerWeak,
      });
      expect(report.errors, isNotEmpty);
    });

    test('kuchsiz sovutgich ogohlantirish beradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: intelLga,
        PcSlot.cooler: coolerWeak,
      });
      expect(report.warnings, isNotEmpty);
      expect(report.errors, isEmpty);
    });
  });

  group('Quvvat bloki', () {
    test('kuchsiz PSU xato beradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.gpu: gpuBig,
        PcSlot.psu: part(
          id: 'psu-300',
          category: 'psu',
          specs: const {'quvvat': '300', 'uzunlik': '140'},
        ),
      });
      expect(report.errors.any((e) => e.message.contains('Quvvat bloki')),
          isTrue);
    });

    test('chegaradagi PSU ogohlantiradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.gpu: gpuBig,
        PcSlot.psu: part(
          id: 'psu-450',
          category: 'psu',
          specs: const {'quvvat': '450', 'uzunlik': '140'},
        ),
      });
      expect(report.warnings.isNotEmpty || report.errors.isNotEmpty, isTrue);
    });

    test('kuchli PSU muammosiz', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.gpu: gpuBig,
        PcSlot.psu: psu1000,
      });
      expect(report.errors, isEmpty);
    });

    test('quvvat iste\u2018moli hisoblanadi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5, // 105
        PcSlot.gpu: gpuSmall, // 115
        PcSlot.motherboard: mbAm5, // 40
      });
      expect(report.estimatedWatts, 105 + 115 + 40);
      expect(report.recommendedPsu, greaterThanOrEqualTo(450));
    });
  });

  group('Grafika', () {
    test('grafikasiz protsessor videokartasiz xato beradi', () {
      final report = CompatibilityChecker.check({PcSlot.cpu: intelLga});
      expect(
        report.errors.any((e) => e.message.contains('grafika')),
        isTrue,
      );
    });

    test('grafikali protsessor videokartasiz ishlaydi', () {
      final report = CompatibilityChecker.check({PcSlot.cpu: ryzenAm5});
      expect(report.errors, isEmpty);
    });
  });

  group('To\u2018liq yig\u2018ilma', () {
    test('majburiy qismlar yetishmasa isComplete false', () {
      final report = CompatibilityChecker.check({PcSlot.cpu: ryzenAm5});
      expect(report.isComplete, isFalse);
      expect(report.missingSlots, contains(PcSlot.motherboard));
      expect(report.missingSlots, isNot(contains(PcSlot.gpu)));
    });

    test('to\u2018g\u2018ri yig\u2018ilma valid', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.motherboard: mbAm5,
        PcSlot.ram: ramDdr5,
        PcSlot.gpu: gpuSmall,
        PcSlot.ssd: ssd,
        PcSlot.psu: psu650,
        PcSlot.pcCase: caseAtx,
        PcSlot.cooler: coolerAm5,
      });
      expect(report.isComplete, isTrue);
      expect(report.errors, isEmpty);
      expect(report.isValid, isTrue);
    });

    test('umumiy narx yig\u2018indisi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: part(id: 'a', category: 'cpu', price: 1000000),
        PcSlot.ram: part(id: 'b', category: 'ram', price: 500000),
      });
      expect(report.totalPrice, 1500000);
    });

    test('omborda yo\u2018q qism ogohlantiradi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: part(
          id: 'cpu-out',
          category: 'cpu',
          stock: 0,
          specs: const {'socket': 'AM5', 'grafika': 'bor'},
        ),
      });
      expect(
        report.warnings.any((w) => w.message.contains('omborda')),
        isTrue,
      );
    });
  });

  group('Muammo kodlari', () {
    test('har bir xato barqaror kodga ega', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.motherboard: mbAm4,
      });
      expect(report.errors, isNotEmpty);
      for (final issue in report.errors) {
        expect(issue.code, isNotEmpty);
      }
      expect(report.errors.map((e) => e.code), contains('cpu_mb_socket'));
    });

    test('muammo tegishli slotlarni ko\u2018rsatadi', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.motherboard: mbAm4,
      });
      final issue =
          report.errors.firstWhere((e) => e.code == 'cpu_mb_socket');
      expect(issue.slots, contains(PcSlot.cpu));
      expect(issue.slots, contains(PcSlot.motherboard));
      expect(issue.slots, isNot(contains(PcSlot.cooler)));
    });

    test('quvvat yetishmovchiligi faqat psu slotiga tegishli', () {
      final report = CompatibilityChecker.check({
        PcSlot.cpu: ryzenAm5,
        PcSlot.gpu: gpuBig,
        PcSlot.psu: part(
          id: 'psu-300',
          category: 'psu',
          specs: const {'quvvat': '300', 'uzunlik': '140'},
        ),
      });
      final issue =
          report.errors.firstWhere((e) => e.code == 'psu_insufficient');
      expect(issue.slots, {PcSlot.psu});
    });
  });

  group('compatibleOptions', () {
    test('mos kelmaydigan platalarni filtrlaydi', () {
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.motherboard,
        candidates: [mbAm5, mbAm4],
        selected: {PcSlot.cpu: ryzenAm5},
      );
      expect(options.map((p) => p.id), ['mb-am5']);
    });

    test('hech nima tanlanmagan bo\u2018lsa hammasi mos', () {
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.motherboard,
        candidates: [mbAm5, mbAm4],
        selected: const {},
      );
      expect(options.length, 2);
    });

    test('grafikasiz protsessor sovutgich ro\u2018yxatini bloklamaydi', () {
      // intelLga da integratsiyalangan grafika yo'q va videokarta hali
      // tanlanmagan — bu mavjud muammo sovutgichlarga taalluqli emas.
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.cooler,
        candidates: [coolerAm5, coolerWeak],
        selected: {PcSlot.cpu: intelLga},
      );
      expect(options.length, 2);
    });

    test('grafikasiz protsessorda videokartalar mos ko\u2018rinadi', () {
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.gpu,
        candidates: [gpuBig, gpuSmall],
        selected: {PcSlot.cpu: intelLga},
      );
      expect(options.length, 2);
    });

    test('kuchsiz quvvat bloki sovutgichlarni bloklamaydi', () {
      final weakPsu = part(
        id: 'psu-300',
        category: 'psu',
        specs: const {'quvvat': '300', 'uzunlik': '140'},
      );
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.cooler,
        candidates: [coolerAm5],
        selected: {
          PcSlot.cpu: ryzenAm5,
          PcSlot.gpu: gpuBig,
          PcSlot.psu: weakPsu,
          PcSlot.pcCase: caseAtx,
        },
      );
      expect(options, hasLength(1));
    });

    test('kuchsiz quvvat bloki o\u2018rniga kuchlisi taklif qilinadi', () {
      final weakPsu = part(
        id: 'psu-300',
        category: 'psu',
        specs: const {'quvvat': '300', 'uzunlik': '140'},
      );
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.psu,
        candidates: [weakPsu, psu1000],
        selected: {
          PcSlot.cpu: ryzenAm5,
          PcSlot.gpu: gpuBig,
          PcSlot.pcCase: caseAtx,
        },
      );
      expect(options.map((p) => p.id), ['psu-1000']);
    });

    test('almashtirilayotgan qismning o\u2018zi hisobga olinmaydi', () {
      // Slotda allaqachon nomos plata turibdi — nomzodlar shunga qaramay
      // to'g'ri baholanishi kerak.
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.motherboard,
        candidates: [mbAm5, mbAm4],
        selected: {PcSlot.cpu: ryzenAm5, PcSlot.motherboard: mbAm4},
      );
      expect(options.map((p) => p.id), ['mb-am5']);
    });

    test('korpus tanlanganda uzun videokarta chiqarib tashlanadi', () {
      final options = CompatibilityChecker.compatibleOptions(
        slot: PcSlot.gpu,
        candidates: [gpuBig, gpuSmall],
        selected: {PcSlot.pcCase: caseSmall},
      );
      expect(options.map((p) => p.id), ['gpu-small']);
    });
  });
}
