import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// One removable filter chip in the scope bar.
class ListScopeChip {
  final String label;
  final VoidCallback onRemove;
  const ListScopeChip(this.label, this.onRemove);
}

// ─────────────────────────────────────────────────────────────────────────────
// "Showing 248 of 611 products" + the filters that got it there.
//
// This line is the export contract: whatever it states is exactly what the
// Export button will produce. It sits directly under the filter row on every
// list page, so the scope is never something the user has to infer from the
// table.
// ─────────────────────────────────────────────────────────────────────────────
class ListScopeBar extends StatelessWidget {
  final int shown;
  final int total;

  /// Plural noun — "products", "clients", "purchase orders".
  final String noun;
  final List<ListScopeChip> chips;

  /// Rows ticked in the table, if the page supports selection.
  final int selectedCount;
  final VoidCallback? onClearSelection;

  const ListScopeBar({
    super.key,
    required this.shown,
    required this.total,
    required this.noun,
    this.chips = const [],
    this.selectedCount = 0,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colors.background.computeLuminance() > 0.5
            ? const Color(0xFFFAF9F7)
            : colors.inputFill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.divider),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
              children: [
                const TextSpan(text: 'Showing '),
                TextSpan(
                  text: '$shown of $total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                TextSpan(text: ' $noun'),
              ],
            ),
          ),
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
              fontFamily: 'Poppins',
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
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryOrange,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
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
