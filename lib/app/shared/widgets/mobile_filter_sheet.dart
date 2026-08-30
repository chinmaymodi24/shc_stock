import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mobile counterpart of the web FilterBar's pill row. Web's MultiSelectFilterPill
// / SingleSelectFilterPill each hide their options behind a second tap — an
// OverlayPortal dropdown floating below the pill. That works in the web
// toolbar's open canvas, but inside a modal bottom sheet the dropdown has
// nowhere reliable to render (it's fighting the sheet's own gesture/overlay
// handling and would open and immediately swallow-close on touch). So mobile
// skips the second tap entirely: the AppBar filter icon opens a sheet that
// shows every option directly as selectable chips — same RxSet/RxString
// controller bindings as web, just laid out flat instead of hidden behind a
// dropdown.
// ─────────────────────────────────────────────────────────────────────────────

/// AppBar action that opens [showMobileFilterSheet] with the page's filter
/// groups. Every list page's mobile AppBar uses this instead of showing the
/// pills inline, so the filter UI stays reachable without crowding the row
/// that already holds search.
class MobileFilterButton extends StatelessWidget {
  final List<Widget> filters;
  final VoidCallback? onClear;

  /// How many filters are currently applied. Above zero the icon turns brand
  /// orange and carries a count badge — without it there was nothing on the
  /// collapsed AppBar to say the list was filtered.
  final int activeCount;

  const MobileFilterButton({
    super.key,
    required this.filters,
    this.onClear,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = activeCount > 0;
    return IconButton(
      tooltip: active
          ? '$activeCount filter${activeCount == 1 ? '' : 's'} applied'
          : 'Filters',
      onPressed: () =>
          showMobileFilterSheet(context, filters: filters, onClear: onClear),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            color: active ? AppColors.primaryOrange : colors.textPrimary,
            size: 24,
          ),
          if (active)
            Positioned(
              top: -5,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(999),
                  // Punches the badge out of the icon behind it.
                  border: Border.all(color: colors.topBarBg, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet holding the page's filter groups — same data/controller
/// bindings as the web FilterBar's pills, laid out as flat chip groups.
Future<void> showMobileFilterSheet(
  BuildContext context, {
  required List<Widget> filters,
  VoidCallback? onClear,
}) {
  final colors = context.appColors;
  return showModalBottomSheet(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(height: 18),
                        filters[i],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 14),
              // Action bar — Clear all on the left, Apply on the right.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClear,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Mobile-native replacement for the web's MultiSelectFilterPill — instead
/// of hiding options behind a second dropdown tap, every option is a
/// directly-tappable chip. Same [selected] RxSet the web pill toggles.
class MobileFilterChipGroup extends StatelessWidget {
  final String label;
  final RxSet<String> selected;
  final List<String> items;
  final ValueChanged<String> onToggle;

  const MobileFilterChipGroup({
    super.key,
    required this.label,
    required this.selected,
    required this.items,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textHint,
            fontFamily: 'Poppins',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(
            'No options',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          )
        else
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => _Chip(
                      label: item,
                      active: selected.contains(item),
                      onTap: () => onToggle(item),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

/// Mobile-native replacement for the web's SingleSelectFilterPill — every
/// option is a directly-tappable chip instead of hiding behind a dropdown.
/// Same [value] the web pill sets.
class MobileFilterChoiceGroup extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const MobileFilterChoiceGroup({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: colors.textHint,
            fontFamily: 'Poppins',
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => _Chip(
                  label: item,
                  active: value == item,
                  onTap: () => onChanged(item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryOrange.withValues(alpha: 0.12)
              : colors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.primaryOrange : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The tick's space is reserved whether or not the chip is
            // selected — otherwise selecting one widens it and reflows the
            // whole Wrap, bumping the next chip onto another line.
            Icon(
              Icons.check_rounded,
              size: 14,
              color: active ? AppColors.primaryOrange : Colors.transparent,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                // Constant weight — a bolder selected label would also
                // change the chip's width and reflow the row.
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primaryOrange : colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
