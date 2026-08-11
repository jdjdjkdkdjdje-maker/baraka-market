import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/specs.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/database/app_database.dart';
import '../../data/models/app_models.dart';
import '../../data/models/enums.dart';
import 'compatibility.dart';

/// KOMPYUTER YIG'ISH — komponentlar tanlanadi, tizim moslikni avtomatik
/// tekshiradi, umumiy narx hisoblanadi. To'liq offline ishlaydi.
class PcBuilderScreen extends ConsumerStatefulWidget {
  const PcBuilderScreen({super.key});

  @override
  ConsumerState<PcBuilderScreen> createState() => _PcBuilderScreenState();
}

class _PcBuilderScreenState extends ConsumerState<PcBuilderScreen> {
  final Map<PcPartType, Product?> _selection = {};

  static const Map<PcPartType, IconData> _partIcons = {
    PcPartType.cpu: Icons.memory,
    PcPartType.motherboard: Icons.developer_board,
    PcPartType.ram: Icons.sd_card,
    PcPartType.gpu: Icons.videogame_asset,
    PcPartType.ssd: Icons.storage,
    PcPartType.hdd: Icons.album,
    PcPartType.psu: Icons.power,
    PcPartType.caseUnit: Icons.computer,
    PcPartType.cooler: Icons.ac_unit_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final checks = checkBuild(_selection);
    final allOk = isBuildCompatible(_selection);
    final total = buildTotalPrice(_selection);
    final builds = ref.watch(pcBuildsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompyuter yig\u2018ish'),
        actions: [
          if (builds.isNotEmpty)
            IconButton(
              tooltip: 'Saqlangan yig\u2018ilmalar',
              icon: const Icon(Icons.folder_open_rounded),
              onPressed: () => _showSavedBuilds(context, builds),
            ),
        ],
      ),
      body: Column(
        children: [
          // Moslik paneli
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: allOk
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allOk
                    ? AppColors.success.withOpacity(0.6)
                    : AppColors.danger.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  allOk
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: allOk ? AppColors.success : AppColors.danger,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allOk
                            ? '\u2713 Komponentlar mos'
                            : '\u2715 Komponentlar mos emas',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: allOk
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                      Text(
                        allOk
                            ? 'Barcha tekshiruvlardan o\u2018tdi'
                            : 'Quyidagi muammolarga e\u2018tibor bering',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Jami narx',
                      style:
                          TextStyle(fontSize: 10.5, color: AppColors.textDim),
                    ),
                    Text(
                      formatSum(total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tekshiruvlar ro'yxati (ixcham)
          if (!allOk)
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: checks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final check = checks[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: check.ok
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.danger.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              check.ok ? Icons.check_rounded : Icons.close_rounded,
                              size: 14,
                              color: check.ok
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              check.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: check.ok
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        if (check.details.isNotEmpty)
                          SizedBox(
                            width: 220,
                            child: Text(
                              check.details,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textDim),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Komponentlar ro'yxati
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: PcPartType.values.length,
              itemBuilder: (context, i) {
                final type = PcPartType.values[i];
                final selected = _selection[type];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openPicker(type),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected != null
                                ? AppColors.primary.withOpacity(0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _partIcons[type],
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.label,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selected?.name ?? type.emptyLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected != null
                                          ? AppColors.text
                                          : AppColors.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected != null) ...[
                              Text(
                                formatSum(selected.price),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close_rounded,
                                    size: 17, color: AppColors.textDim),
                                onPressed: () =>
                                    setState(() => _selection[type] = null),
                              ),
                            ] else
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textDim),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pastki amallar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selection.values.any((p) => p != null)
                        ? _saveBuild
                        : null,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Saqlash'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _selection.values.any((p) => p != null)
                        ? _addAllToCart
                        : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded,
                        size: 18),
                    label: const Text('Savatga qo\u2018shish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPicker(PcPartType type) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PartPickerSheet(
        type: type,
        selected: _selection[type],
        onPicked: (p) {
          setState(() => _selection[type] = p);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _addAllToCart() {
    var count = 0;
    for (final p in _selection.values) {
      if (p != null) {
        ref.read(cartRepositoryProvider).add(p.id);
        count++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count ta komponent savatga qo\u2018shildi')),
    );
  }

  Future<void> _saveBuild() async {
    final controller = TextEditingController(text: 'Mening kompyuterim');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Yig\u2018ilmani saqlash'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nomi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    final components = <String, String>{
      for (final e in _selection.entries)
        if (e.value != null) e.key.name: e.value!.id,
    };

    await ref.read(pcBuildRepositoryProvider).save(
          id: const Uuid().v4(),
          name: name.trim(),
          componentsJson: encodeSpecs(components),
          totalPrice: buildTotalPrice(_selection),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yig\u2018ilma saqlandi')),
    );
  }

  void _showSavedBuilds(BuildContext context, List<PcBuild> builds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref) {
              final list = ref.watch(pcBuildsProvider).valueOrNull ?? [];
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Saqlangan yig\u2018ilmalar',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Hali saqlangan yig\u2018ilmalar yo\u2018q'),
                    ),
                  ...list.map(
                    (b) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.computer_rounded,
                          color: AppColors.primary),
                      title: Text(b.name),
                      subtitle: Text(formatSum(b.totalPrice)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger),
                        onPressed: () =>
                            ref.read(pcBuildRepositoryProvider).delete(b.id),
                      ),
                      onTap: () async {
                        final map = parseSpecs(b.componentsJson);
                        final repo = ref.read(productRepositoryProvider);
                        final newSelection = <PcPartType, Product?>{};
                        for (final entry in map.entries) {
                          final type = PcPartType.values.firstWhere(
                            (t) => t.name == entry.key,
                            orElse: () => PcPartType.cpu,
                          );
                          newSelection[type] =
                              await repo.getById(entry.value);
                        }
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        setState(() {
                          _selection
                            ..clear()
                            ..addAll(newSelection);
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Komponent tanlash paneli.
class _PartPickerSheet extends ConsumerWidget {
  const _PartPickerSheet({
    required this.type,
    required this.onPicked,
    this.selected,
  });

  final PcPartType type;
  final Product? selected;
  final ValueChanged<Product> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final options = products
        .where((p) => parseSpecs(p.specsJson)['pc_part'] == type.specValue)
        .toList()
      ..sort((a, b) => b.popularity.compareTo(a.popularity));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${type.label}ni tanlang',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: options.isEmpty
                  ? const Center(
                      child: Text('Bu turdagi mahsulotlar topilmadi'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: options.length,
                      itemBuilder: (context, i) {
                        final p = options[i];
                        final specs = parseSpecs(p.specsJson);
                        final isSelected = selected?.id == p.id;
                        final keySpecs = <String>[
                          if (specs['socket'] != null)
                            'Socket: ${specs['socket']}',
                          if (specs['ram_type'] != null)
                            'RAM: ${specs['ram_type']}',
                          if (specs['tdp'] != null) 'TDP: ${specs['tdp']}W',
                          if (specs['psu_watt'] != null)
                            '${specs['psu_watt']}W',
                          if (specs['gpu_length'] != null)
                            '${specs['gpu_length']}mm',
                          if (specs['cooler_height'] != null)
                            '${specs['cooler_height']}mm',
                          if (specs['Hajm'] != null) specs['Hajm']!,
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onPicked(p),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(p.emoji,
                                        style:
                                            const TextStyle(fontSize: 26)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (keySpecs.isNotEmpty)
                                            Text(
                                              keySpecs.join('  \u2022  '),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: AppColors.textDim,
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatSum(p.price),
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
