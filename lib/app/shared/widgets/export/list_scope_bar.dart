import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// One removable filter chip in the scope bar.
class ListScopeChip {
  final String label;
  final VoidCallback onRemove;
  const ListScopeChip(this.label, this.onRemove);
}

// ─────────────────────────────────────────────────────────────────────────────
// The active filters that narrowed the list, plus the current selection.
//
// This is the export contract: whatever it states is exactly what the Export
// button will produce. It sits directly under the filter row on every list
// page. It carries no "Showing N of M" count — the table footer already prints
// one ("Showing 1 to 10 of 29 entries"), and two counts on one screen only
// invited the reader to reconcile them.
//
// With nothing filtered and nothing selected there is nothing to say, so the
// bar takes no space at all rather than sitting there as an empty box. It
// carries its own leading gap for the same reason: a sibling SizedBox at the
// call site would survive the collapse and leave a hole where the bar was.
// ─────────────────────────────────────────────────────────────────────────────
class ListScopeBar extends StatelessWidget {
  final List<ListScopeChip> chips;

  /// Rows ticked in the table, if the page supports selection.
  final int selectedCount;
  final VoidCallback? onClearSelection;

  const ListScopeBar({
    super.key,
    this.chips = const [],
    this.selectedCount = 0,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (chips.isEmpty && selectedCount == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colors.tableHeaderBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.divider),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final chip in chips) _Chip(chip: chip),
          if (selectedCount > 0)
            _SelectionPill(count: selectedCount, onClear: onClearSelection),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final ListScopeChip chip;
  const _Chip({required this.chip});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: chip.onRemove,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionPill extends StatelessWidget {
  final int count;
  final VoidCallback? onClear;
  const _SelectionPill({required this.count, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.primaryOrange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count selected',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
