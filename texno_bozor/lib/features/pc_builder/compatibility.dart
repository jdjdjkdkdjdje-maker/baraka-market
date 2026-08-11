import '../../data/models/models.dart';

/// Yig'ilma slotlari — kompyuter qismlari.
enum PcSlot {
  cpu('Protsessor', 'cpu', required: true),
  motherboard('Motherboard', 'motherboard', required: true),
  ram('Operativ xotira', 'ram', required: true),
  gpu('Videokarta', 'gpu'),
  ssd('SSD disk', 'ssd', required: true),
  hdd('Qattiq disk', 'hdd'),
  psu('Quvvat bloki', 'psu', required: true),
  pcCase('Korpus', 'case', required: true),
  cooler('Sovutgich', 'cooler');

  const PcSlot(this.label, this.categoryId, {this.required = false});

  final String label;
  final String categoryId;

  /// Ishlaydigan kompyuter uchun majburiy qismmi?
  final bool required;
}

/// Moslik tekshiruvi natijasi.
enum IssueLevel { error, warning, info }

class CompatibilityIssue {
  const CompatibilityIssue(
    this.level,
    this.message, {
    this.code = '',
    this.slots = const {},
  });

  final IssueLevel level;
  final String message;

  /// Muammoning barqaror kodi (matndan mustaqil). Filtrlash va testlar
  /// aynan shu kodga tayanadi.
  final String code;

  /// Muammo qaysi slotlarga tegishli. Bu qism tanlash oynasida kerak:
  /// masalan protsessor bilan bog'liq xato sovutgich ro'yxatini
  /// "mos emas" deb belgilab qo'ymasligi uchun.
  final Set<PcSlot> slots;

  bool get isError => level == IssueLevel.error;
}

class BuildReport {
  const BuildReport({
    required this.issues,
    required this.totalPrice,
    required this.estimatedWatts,
    required this.missingSlots,
  });

  final List<CompatibilityIssue> issues;
  final int totalPrice;

  /// Taxminiy quvvat iste'moli (W).
  final int estimatedWatts;
  final List<PcSlot> missingSlots;

  List<CompatibilityIssue> get errors =>
      issues.where((i) => i.level == IssueLevel.error).toList();

  List<CompatibilityIssue> get warnings =>
      issues.where((i) => i.level == IssueLevel.warning).toList();

  bool get isComplete => missingSlots.isEmpty;

  /// Yig'ilma ishlaydimi: majburiy qismlar bor va xatolik yo'q.
  bool get isValid => isComplete && errors.isEmpty;

  /// Tavsiya etilgan quvvat bloki (zaxira bilan).
  int get recommendedPsu {
    final withHeadroom = (estimatedWatts * 1.4).round();
    for (final size in [450, 550, 650, 750, 850, 1000, 1200]) {
      if (withHeadroom <= size) return size;
    }
    return 1600;
  }
}

/// KOMPYUTER YIG'ISH — moslik tekshiruvi.
///
/// Butunlay qurilma ichida ishlaydi: soket, xotira turi, korpus o'lchami,
/// quvvat bloki va sovutgich mosligini avtomatik nazorat qiladi.
class CompatibilityChecker {
  const CompatibilityChecker._();

  /// Komponentlarning taxminiy quvvat iste'moli.
  static int _watts(PcSlot slot, Product product) {
    switch (slot) {
      case PcSlot.cpu:
        return product.specInt('tdp', fallback: 95);
      case PcSlot.gpu:
        return product.specInt('tdp', fallback: 180);
      case PcSlot.motherboard:
        return 40;
      case PcSlot.ram:
        return 10;
      case PcSlot.ssd:
        return 8;
      case PcSlot.hdd:
        return 10;
      case PcSlot.cooler:
        return product.spec('tip') == 'Suyuqlik' ? 15 : 6;
      case PcSlot.psu:
      case PcSlot.pcCase:
        return 0;
    }
  }

  /// Yig'ilmani to'liq tekshiradi.
  static BuildReport check(Map<PcSlot, Product> parts) {
    final issues = <CompatibilityIssue>[];

    final cpu = parts[PcSlot.cpu];
    final mb = parts[PcSlot.motherboard];
    final ram = parts[PcSlot.ram];
    final gpu = parts[PcSlot.gpu];
    final psu = parts[PcSlot.psu];
    final pcCase = parts[PcSlot.pcCase];
    final cooler = parts[PcSlot.cooler];

    // 1. Protsessor ↔ Motherboard soketi.
    if (cpu != null && mb != null) {
      final cpuSocket = cpu.spec('socket').trim().toUpperCase();
      final mbSocket = mb.spec('socket').trim().toUpperCase();
      if (cpuSocket.isNotEmpty && mbSocket.isNotEmpty) {
        if (cpuSocket != mbSocket) {
          issues.add(CompatibilityIssue(
            IssueLevel.error,
            'Protsessor soketi ($cpuSocket) motherboard soketiga '
            '($mbSocket) to\u2018g\u2018ri kelmaydi.',
            code: 'cpu_mb_socket',
            slots: const {PcSlot.cpu, PcSlot.motherboard},
          ));
        } else {
          issues.add(CompatibilityIssue(
            IssueLevel.info,
            'Protsessor va motherboard soketi mos: $cpuSocket.',
            code: 'cpu_mb_socket_ok',
            slots: const {PcSlot.cpu, PcSlot.motherboard},
          ));
        }
      }
    }

    // 2. Xotira turi: motherboard ↔ RAM ↔ protsessor.
    if (mb != null && ram != null) {
      final mbMemory = mb.spec('xotira').toUpperCase();
      final ramType = ram.spec('xotira').toUpperCase();
      if (mbMemory.isNotEmpty && ramType.isNotEmpty) {
        if (!mbMemory.contains(ramType)) {
          issues.add(CompatibilityIssue(
            IssueLevel.error,
            'Motherboard $mbMemory xotirani qo\u2018llaydi, tanlangan modul '
            'esa $ramType.',
            code: 'mb_ram_type',
            slots: const {PcSlot.motherboard, PcSlot.ram},
          ));
        }
      }
    }
    if (cpu != null && ram != null) {
      final cpuMemory = cpu.spec('xotira').toUpperCase();
      final ramType = ram.spec('xotira').toUpperCase();
      if (cpuMemory.isNotEmpty &&
          ramType.isNotEmpty &&
          !cpuMemory.contains(ramType)) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          'Protsessor $cpuMemory xotira bilan ishlaydi, siz $ramType '
          'tanladingiz.',
          code: 'cpu_ram_type',
          slots: const {PcSlot.cpu, PcSlot.ram},
        ));
      }
    }

    // 3. Korpus ↔ Motherboard formati.
    if (pcCase != null && mb != null) {
      final caseForm = pcCase.spec('form').toUpperCase();
      final mbForm = mb.spec('form').toUpperCase();
      const order = {'MINI-ITX': 1, 'ITX': 1, 'MATX': 2, 'ATX': 3, 'E-ATX': 4};
      final caseSize = order[caseForm];
      final mbSize = order[mbForm];
      if (caseSize != null && mbSize != null && mbSize > caseSize) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          '$mbForm motherboard $caseForm korpusga sig\u2018maydi.',
          code: 'case_mb_form',
          slots: const {PcSlot.motherboard, PcSlot.pcCase},
        ));
      }
    }

    // 4. Korpus ↔ Videokarta uzunligi.
    if (pcCase != null && gpu != null) {
      final maxLength = pcCase.specInt('gpu_uzunlik');
      final gpuLength = gpu.specInt('uzunlik');
      if (maxLength > 0 && gpuLength > 0 && gpuLength > maxLength) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          'Videokarta uzunligi $gpuLength mm — korpusda faqat $maxLength mm '
          'joy bor.',
          code: 'case_gpu_length',
          slots: const {PcSlot.gpu, PcSlot.pcCase},
        ));
      }
    }

    // 5. Korpus ↔ Sovutgich balandligi.
    if (pcCase != null && cooler != null) {
      final maxHeight = pcCase.specInt('kuler_balandlik');
      final coolerHeight = cooler.specInt('balandlik');
      if (maxHeight > 0 &&
          coolerHeight > 0 &&
          cooler.spec('tip') != 'Suyuqlik' &&
          coolerHeight > maxHeight) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          'Sovutgich balandligi $coolerHeight mm — korpusga $maxHeight mm '
          'gacha sig\u2018adi.',
          code: 'case_cooler_height',
          slots: const {PcSlot.cooler, PcSlot.pcCase},
        ));
      }
    }

    // 6. Sovutgich ↔ Protsessor (soket va TDP).
    if (cooler != null && cpu != null) {
      final supported = cooler.spec('socket').toUpperCase();
      final cpuSocket = cpu.spec('socket').toUpperCase();
      if (supported.isNotEmpty &&
          cpuSocket.isNotEmpty &&
          !supported.contains(cpuSocket)) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          'Sovutgich $cpuSocket soketini qo\u2018llamaydi.',
          code: 'cooler_socket',
          slots: const {PcSlot.cooler, PcSlot.cpu},
        ));
      }
      final coolerTdp = cooler.specInt('tdp');
      final cpuTdp = cpu.specInt('tdp');
      if (coolerTdp > 0 && cpuTdp > 0 && cpuTdp > coolerTdp) {
        issues.add(CompatibilityIssue(
          IssueLevel.warning,
          'Protsessor ${cpuTdp}W issiqlik chiqaradi, sovutgich esa '
          '${coolerTdp}W gacha mo\u2018ljallangan.',
          code: 'cooler_tdp',
          slots: const {PcSlot.cooler, PcSlot.cpu},
        ));
      }
    }

    // 7. Protsessorda integratsiyalangan grafika yo'q va videokarta ham yo'q.
    if (cpu != null && gpu == null) {
      final graphics = cpu.spec('grafika').toLowerCase();
      if (graphics.contains('yo\u2018q') || graphics.contains('yoq')) {
        issues.add(const CompatibilityIssue(
          IssueLevel.error,
          'Bu protsessorda integratsiyalangan grafika yo\u2018q — '
          'videokarta qo\u2018shish shart.',
          code: 'cpu_needs_gpu',
          slots: {PcSlot.cpu, PcSlot.gpu},
        ));
      }
    }

    // 8. Quvvat bloki yetarlimi?
    var watts = 0;
    var totalPrice = 0;
    parts.forEach((slot, product) {
      watts += _watts(slot, product);
      totalPrice += product.price;
    });
    final needed = (watts * 1.3).round();

    if (psu != null) {
      final psuWatts = psu.specInt('quvvat');
      if (psuWatts > 0) {
        if (psuWatts < watts) {
          issues.add(CompatibilityIssue(
            IssueLevel.error,
            'Quvvat bloki yetarli emas: tizim ~${watts}W talab qiladi, '
            'blok esa ${psuWatts}W.',
            // Quvvat yetishmovchiligi asosan protsessor va videokartaga
            // bog'liq, shuning uchun ular ham "mos emas" deb belgilanadi.
            code: 'psu_insufficient',
            // Faqat quvvat bloki: yechim — kuchliroq blok tanlash, boshqa
            // qismlarni ro'yxatdan chiqarib tashlash emas.
            slots: const {PcSlot.psu},
          ));
        } else if (psuWatts < needed) {
          issues.add(CompatibilityIssue(
            IssueLevel.warning,
            'Quvvat bloki chegarada ishlaydi (${psuWatts}W). '
            'Kamida ${needed}W tavsiya etiladi.',
            code: 'psu_tight',
            slots: const {PcSlot.psu},
          ));
        } else {
          issues.add(CompatibilityIssue(
            IssueLevel.info,
            'Quvvat bloki yetarli: ${psuWatts}W (tizim ~${watts}W).',
            code: 'psu_ok',
            slots: const {PcSlot.psu},
          ));
        }
      }
      // Videokartaning tavsiya etilgan quvvati.
      if (gpu != null) {
        final gpuNeeds = gpu.specInt('quvvat');
        if (gpuNeeds > 0 && psuWatts > 0 && psuWatts < gpuNeeds) {
          issues.add(CompatibilityIssue(
            IssueLevel.warning,
            'Videokarta ishlab chiqaruvchisi ${gpuNeeds}W quvvat blokini '
            'tavsiya qiladi.',
            code: 'gpu_psu_recommend',
            slots: const {PcSlot.psu, PcSlot.gpu},
          ));
        }
      }
    }

    // 9. Korpus ↔ Quvvat bloki uzunligi.
    if (pcCase != null && psu != null) {
      final maxPsu = pcCase.specInt('psu_uzunlik');
      final psuLength = psu.specInt('uzunlik');
      if (maxPsu > 0 && psuLength > 0 && psuLength > maxPsu) {
        issues.add(CompatibilityIssue(
          IssueLevel.error,
          'Quvvat bloki uzunligi $psuLength mm — korpusda $maxPsu mm joy bor.',
          code: 'case_psu_length',
          slots: const {PcSlot.psu, PcSlot.pcCase},
        ));
      }
    }

    // 10. Ombordagi mavjudlik.
    parts.forEach((slot, product) {
      if (!product.inStock) {
        issues.add(CompatibilityIssue(
          IssueLevel.warning,
          '${product.name} hozir omborda yo\u2018q.',
          code: 'out_of_stock',
          slots: {slot},
        ));
      }
    });

    final missing = PcSlot.values
        .where((s) => s.required && !parts.containsKey(s))
        .toList();

    return BuildReport(
      issues: issues,
      totalPrice: totalPrice,
      estimatedWatts: watts,
      missingSlots: missing,
    );
  }

  /// Tanlangan qismlarga mos keladigan mahsulotlarni filtrlaydi.
  ///
  /// Masalan CPU tanlangan bo'lsa, motherboard ro'yxatida faqat mos soketli
  /// platalar qoladi.
  ///
  /// Ikki shart birga tekshiriladi, aks holda foydalanuvchi tupikka tushadi:
  ///  1. Xato aynan shu nomzod qo'shilgandan keyin YANGI paydo bo'lishi kerak
  ///     (allaqachon mavjud muammo boshqa slotlarni bloklamasin);
  ///  2. Xato shu slotga tegishli bo'lishi kerak — masalan quvvat bloki
  ///     kuchsizligi sovutgichlar ro'yxatini bo'shatib qo'ymasin, uni
  ///     quvvat blokini almashtirib tuzatiladi.
  static List<Product> compatibleOptions({
    required PcSlot slot,
    required List<Product> candidates,
    required Map<PcSlot, Product> selected,
  }) {
    final baseline = _errorKeys(
      check(Map<PcSlot, Product>.from(selected)..remove(slot)),
    );

    return candidates.where((candidate) {
      final trial = Map<PcSlot, Product>.from(selected)..[slot] = candidate;
      final blocking = check(trial).errors.where((issue) {
        final isNew = !baseline.contains(_key(issue));
        final isRelated = issue.slots.isEmpty || issue.slots.contains(slot);
        return isNew && isRelated;
      });
      return blocking.isEmpty;
    }).toList();
  }

  static String _key(CompatibilityIssue issue) =>
      '${issue.code}|${issue.message}';

  static Set<String> _errorKeys(BuildReport report) =>
      report.errors.map(_key).toSet();
}
