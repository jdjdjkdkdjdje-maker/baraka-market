import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import 'compatibility.dart';

/// KOMPYUTER YIG'ISH — qismlarni tanlash va moslikni tekshirish.
class PcBuilderScreen extends ConsumerStatefulWidget {
  const PcBuilderScreen({super.key});

  @override
  ConsumerState<PcBuilderScreen> createState() => _PcBuilderScreenState();
}

class _PcBuilderScreenState extends ConsumerState<PcBuilderScreen> {
  final Map<PcSlot, Product> _parts = {};

  @override
  Widget build(BuildContext context) {
    final report = CompatibilityChecker.check(_parts);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompyuter yig\u2018ish'),
        actions: [
          if (_parts.isNotEmpty)
            IconButton(
              tooltip: 'Tozalash',
              onPressed: () => setState(_parts.clear),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _summaryCard(report),
          const SizedBox(height: 16),
          for (final slot in PcSlot.values) ...[
            _slotTile(slot),
            const SizedBox(height: 10),
          ],
          if (report.issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            _issuesCard(report),
          ],
        ],
      ),
      bottomNavigationBar: _parts.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_parts.length} ta qism',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          Format.price(report.totalPrice),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: report.errors.isEmpty
                            ? () => _addAllToCart(report)
                            : null,
                        child: Text(
                          report.errors.isEmpty
                              ? 'Savatga qo\u2018shish'
                              : 'Moslik xatosi bor',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _summaryCard(BuildReport report) {
    final Color color;
    final IconData icon;
    final String title;
    final String message;

    if (_parts.isEmpty) {
      color = AppColors.accent;
      icon = Icons.build_circle_outlined;
      title = 'Yig\u2018ishni boshlang';
      message = 'Qismlarni tanlang — soket, xotira, quvvat va o\u2018lchamlar '
          'mosligini avtomatik tekshiramiz.';
    } else if (report.errors.isNotEmpty) {
      color = AppColors.danger;
      icon = Icons.error_outline_rounded;
      title = '${report.errors.length} ta moslik xatosi';
      message = 'Quyidagi qismlarni almashtiring — ular birga ishlamaydi.';
    } else if (!report.isComplete) {
      color = AppColors.warning;
      icon = Icons.info_outline_rounded;
      title = 'Yana ${report.missingSlots.length} ta qism kerak';
      message = report.missingSlots.map((s) => s.label).join(', ');
    } else {
      color = AppColors.success;
      icon = Icons.verified_rounded;
      title = 'Yig\u2018ilma to\u2018liq mos!';
      message = 'Barcha qismlar bir-biriga to\u2018g\u2018ri keladi. '
          'Bemalol buyurtma bering.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (_parts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('Quvvat', '~${report.estimatedWatts} W'),
                const SizedBox(width: 20),
                _metric('Tavsiya PSU', '${report.recommendedPsu} W'),
                const SizedBox(width: 20),
                _metric('Narx', Format.shortPrice(report.totalPrice)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _slotTile(PcSlot slot) {
    final product = _parts[slot];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pickPart(slot),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: product == null
                      ? AppColors.surfaceHigh
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _slotIcon(slot),
                  size: 21,
                  color: product == null
                      ? AppColors.textMuted
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          slot.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (slot.required) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product?.name ?? 'Tanlanmagan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: product == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (product != null)
                      Text(
                        Format.price(product.price),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (product != null)
                IconButton(
                  onPressed: () => setState(() => _parts.remove(slot)),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textMuted,
                )
              else
                const Icon(Icons.add_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _slotIcon(PcSlot slot) {
    switch (slot) {
      case PcSlot.cpu:
        return Icons.memory_rounded;
      case PcSlot.motherboard:
        return Icons.developer_board_rounded;
      case PcSlot.ram:
        return Icons.view_module_rounded;
      case PcSlot.gpu:
        return Icons.videogame_asset_rounded;
      case PcSlot.ssd:
        return Icons.storage_rounded;
      case PcSlot.hdd:
        return Icons.album_rounded;
      case PcSlot.psu:
        return Icons.power_rounded;
      case PcSlot.pcCase:
        return Icons.computer_rounded;
      case PcSlot.cooler:
        return Icons.ac_unit_rounded;
    }
  }

  Widget _issuesCard(BuildReport report) {
    final visible = report.issues
        .where((i) => i.level != IssueLevel.info || report.errors.isEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moslik tekshiruvi',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final issue in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (issue.level) {
                      IssueLevel.error => Icons.cancel_rounded,
                      IssueLevel.warning => Icons.warning_amber_rounded,
                      IssueLevel.info => Icons.check_circle_rounded,
                    },
                    size: 16,
                    color: switch (issue.level) {
                      IssueLevel.error => AppColors.danger,
                      IssueLevel.warning => AppColors.warning,
                      IssueLevel.info => AppColors.success,
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickPart(PcSlot slot) async {
    final repository = ref.read(productRepositoryProvider);
    final candidates = await repository.getByCategory(slot.categoryId);
    if (!mounted) return;

    if (candidates.isEmpty) {
      showAppSnack(context, '${slot.label} bo\u2018yicha mahsulot yo\u2018q',
          isError: true);
      return;
    }

    final selected = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PartPicker(
        slot: slot,
        candidates: candidates,
        selected: Map.of(_parts),
      ),
    );

    if (selected != null) setState(() => _parts[slot] = selected);
  }

  Future<void> _addAllToCart(BuildReport report) async {
    final cart = ref.read(cartProvider.notifier);
    for (final product in _parts.values) {
      await cart.add(product.id);
    }
    if (!mounted) return;
    showAppSnack(
      context,
      '${_parts.length} ta qism savatga qo\u2018shildi',
      action: SnackBarAction(
        label: 'Savat',
        onPressed: () => Navigator.of(context).pushNamed('/cart'),
      ),
    );
  }
}

/// Qism tanlash oynasi — mos kelmaydigan variantlarni ajratib ko'rsatadi.
class _PartPicker extends StatefulWidget {
  const _PartPicker({
    required this.slot,
    required this.candidates,
    required this.selected,
  });

  final PcSlot slot;
  final List<Product> candidates;
  final Map<PcSlot, Product> selected;

  @override
  State<_PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<_PartPicker> {
  bool _onlyCompatible = true;

  @override
  Widget build(BuildContext context) {
    final compatible = CompatibilityChecker.compatibleOptions(
      slot: widget.slot,
      candidates: widget.candidates,
      selected: widget.selected,
    );
    final compatibleIds = {for (final p in compatible) p.id};
    final items = _onlyCompatible ? compatible : widget.candidates;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.slot.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${compatible.length}/${widget.candidates.length} mos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _onlyCompatible,
              onChanged: (value) => setState(() => _onlyCompatible = value),
              title: const Text(
                'Faqat mos keladiganlar',
                style: TextStyle(fontSize: 13.5),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.extension_off_rounded,
                    title: 'Mos variant yo\u2018q',
                    message: 'Boshqa qismlarni o\u2018zgartirib '
                        'ko\u2018ring yoki filtrni o\u2018chiring',
                  )
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      final isCompatible = compatibleIds.contains(product.id);
                      return Material(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(product),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.specs.entries
                                            .take(3)
                                            .map((e) => e.value)
                                            .join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            Format.price(product.price),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (!isCompatible)
                                            const AppBadge(
                                              text: 'Mos emas',
                                              color: AppColors.danger,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
