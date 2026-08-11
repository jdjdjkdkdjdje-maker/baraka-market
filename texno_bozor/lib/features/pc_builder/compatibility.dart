import '../../core/constants/app_constants.dart';
import '../../core/utils/specs.dart';
import '../../data/database/app_database.dart';
import '../../data/models/app_models.dart';
import '../../data/models/enums.dart';

/// PC Builder moslik tekshiruvi — to'liq lokal logika.
///
/// Tekshiriladi:
///  - CPU socket vs Ona plata socket
///  - RAM turi vs Ona plata RAM turi
///  - CPU qo'llab-quvvatlaydigan RAM turi
///  - PSU quvvati (CPU TDP + GPU TDP + tizim zaxirasi)
///  - GPU uzunligi vs Korpus sig'imi
///  - Sovutgich balandligi vs Korpus sig'imi
///  - Sovutgich quvvati vs CPU TDP
List<CompatCheck> checkBuild(Map<PcPartType, Product?> parts) {
  final checks = <CompatCheck>[];

  final cpu = parts[PcPartType.cpu];
  final mb = parts[PcPartType.motherboard];
  final ram = parts[PcPartType.ram];
  final gpu = parts[PcPartType.gpu];
  final psu = parts[PcPartType.psu];
  final pcCase = parts[PcPartType.caseUnit];
  final cooler = parts[PcPartType.cooler];

  // Tanlanmagan asosiy komponentlar.
  final missing = PcPartType.values
      .where((t) => parts[t] == null)
      .map((t) => t.label)
      .toList();
  if (missing.isEmpty) {
    checks.add(const CompatCheck(
      ok: true,
      title: 'Barcha komponentlar tanlangan',
    ));
  } else {
    checks.add(CompatCheck(
      ok: false,
      title: 'Tanlanmagan komponentlar bor',
      details: missing.join(', '),
    ));
  }

  // 1. Socket mosligi.
  if (cpu != null && mb != null) {
    final cpuSocket = parseSpecs(cpu.specsJson)['socket'];
    final mbSocket = parseSpecs(mb.specsJson)['socket'];
    if (cpuSocket != null && mbSocket != null) {
      if (cpuSocket == mbSocket) {
        checks.add(CompatCheck(
          ok: true,
          title: 'Socket mos: $cpuSocket',
          details: '${cpu.name} va ${mb.name}',
        ));
      } else {
        checks.add(CompatCheck(
          ok: false,
          title: 'Socket mos emas!',
          details:
              'Protsessor socketi $cpuSocket, ona plata socketi esa $mbSocket. Bitta platformani tanlang.',
        ));
      }
    }
  }

  // 2. RAM turi vs ona plata.
  if (ram != null && mb != null) {
    final ramType = parseSpecs(ram.specsJson)['ram_type'];
    final mbRamType = parseSpecs(mb.specsJson)['ram_type'];
    if (ramType != null && mbRamType != null) {
      if (ramType == mbRamType) {
        checks.add(CompatCheck(
          ok: true,
          title: 'RAM mos: $ramType',
          details: '${ram.name} va ${mb.name}',
        ));
      } else {
        checks.add(CompatCheck(
          ok: false,
          title: 'RAM mos emas!',
          details:
              'Xotira $ramType, ona plata esa $mbRamType qo\u2018llaydi. Boshqa RAM yoki plata tanlang.',
        ));
      }
    }
  }

  // 3. CPU RAM qo'llab-quvvatuvi.
  if (cpu != null && mb != null) {
    final cpuRam = parseSpecs(cpu.specsJson)['ram_type'];
    final mbRamType = parseSpecs(mb.specsJson)['ram_type'];
    if (cpuRam != null && mbRamType != null) {
      final supported = cpuRam.split('/').map((s) => s.trim()).toList();
      if (!supported.contains(mbRamType)) {
        checks.add(CompatCheck(
          ok: false,
          title: 'CPU bu RAM turni qo\u2018llamaydi',
          details:
              '${cpu.name} faqat $cpuRam qo\u2018llaydi, plata esa $mbRamType.',
        ));
      }
    }
  }

  // 4. PSU quvvati.
  final cpuTdp = cpu != null ? specInt(parseSpecs(cpu.specsJson), 'tdp') : null;
  final gpuTdp = gpu != null ? specInt(parseSpecs(gpu.specsJson), 'tdp') : null;
  final psuWatt =
      psu != null ? specInt(parseSpecs(psu.specsJson), 'psu_watt') : null;

  if (psu != null && psuWatt != null) {
    final needed = (cpuTdp ?? 95) +
        (gpuTdp ?? 150) +
        AppConstants.systemBaseWatt;
    if (psuWatt >= needed) {
      checks.add(CompatCheck(
        ok: true,
        title: 'Quvvat yetarli: ${psuWatt}W',
        details: 'Taxminiy iste\u2018mol: ~${needed}W (zaxira bilan)',
      ));
    } else {
      checks.add(CompatCheck(
        ok: false,
        title: 'Quvvat bloki kuchsiz!',
        details:
            'Tizimga ~${needed}W kerak (CPU ${cpuTdp ?? '?'}W + GPU ${gpuTdp ?? '?'}W + ${AppConstants.systemBaseWatt}W), blokda esa ${psuWatt}W. Kamida ${needed}W blok tanlang.',
      ));
    }
  }

  // 5. GPU uzunligi vs korpus.
  if (gpu != null && pcCase != null) {
    final gpuLength = specInt(parseSpecs(gpu.specsJson), 'gpu_length');
    final maxGpu = specInt(parseSpecs(pcCase.specsJson), 'max_gpu_length');
    if (gpuLength != null && maxGpu != null) {
      if (gpuLength <= maxGpu) {
        checks.add(CompatCheck(
          ok: true,
          title: 'Videokarta korpusga sig\u2018adi',
          details: 'GPU ${gpuLength}mm, korpusda maksimal ${maxGpu}mm',
        ));
      } else {
        checks.add(CompatCheck(
          ok: false,
          title: 'Videokarta korpusga sig\u2018maydi!',
          details:
              'GPU uzunligi ${gpuLength}mm, korpus esa maksimal ${maxGpu}mm sig\u2018diradi.',
        ));
      }
    }
  }

  // 6. Sovutgich balandligi vs korpus.
  if (cooler != null && pcCase != null) {
    final coolerHeight =
        specInt(parseSpecs(cooler.specsJson), 'cooler_height');
    final maxCooler = specInt(parseSpecs(pcCase.specsJson), 'max_cooler');
    if (coolerHeight != null && maxCooler != null) {
      if (coolerHeight <= maxCooler) {
        checks.add(CompatCheck(
          ok: true,
          title: 'Sovutgich korpusga sig\u2018adi',
          details: 'Balandligi ${coolerHeight}mm, maksimal ${maxCooler}mm',
        ));
      } else {
        checks.add(CompatCheck(
          ok: false,
          title: 'Sovutgich korpusga sig\u2018maydi!',
          details:
              'Sovutgich ${coolerHeight}mm, korpusda maksimal ${maxCooler}mm joy bor.',
        ));
      }
    }
  }

  // 7. Sovutgich quvvati vs CPU TDP.
  if (cooler != null && cpu != null && cpuTdp != null) {
    final coolerTdp = specInt(parseSpecs(cooler.specsJson), 'cooler_tdp');
    if (coolerTdp != null) {
      if (coolerTdp >= cpuTdp) {
        checks.add(CompatCheck(
          ok: true,
          title: 'Sovutgich CPU ni sovuta oladi',
          details: 'CPU ${cpuTdp}W, sovutgich ${coolerTdp}W gacha',
        ));
      } else {
        checks.add(CompatCheck(
          ok: false,
          title: 'Sovutgich kuchsiz!',
          details:
              'CPU issiqligi ${cpuTdp}W, sovutgich esa ${coolerTdp}W gacha mo\u2018ljallangan.',
        ));
      }
    }
  }

  return checks;
}

/// Umumiy moslik holati: barcha tanlangan komponentlar mosmi?
bool isBuildCompatible(Map<PcPartType, Product?> parts) {
  final checks = checkBuild(parts);
  return checks.every((c) => c.ok);
}

/// Yig'ilishning umumiy narxi.
int buildTotalPrice(Map<PcPartType, Product?> parts) {
  var total = 0;
  for (final p in parts.values) {
    if (p != null) total += p.price;
  }
  return total;
}
