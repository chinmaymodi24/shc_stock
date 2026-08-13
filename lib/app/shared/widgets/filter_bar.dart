import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared list filter bar — search box + rounded filter/sort pills + clear all.
// Every list page (Products, Stock, Transactions, Users, Purchase, Sales,
// Clients, Categories) uses these so the filter UI is identical everywhere.
// ─────────────────────────────────────────────────────────────────────────────

/// Height of a filter pill.
const double kFilterPillHeight = 32;

/// Breathing room between a pill and the dropdown panel below it.
const double _kMenuGap = 6;

/// How far a dropdown sits below the top of its pill.
const double _kMenuOffset = kFilterPillHeight + _kMenuGap;

/// Fixed height of the whole filter row — keeps search and pills aligned.
const double kFilterRowHeight = 44;

// ── Row wrapper ─────────────────────────────────────────────────────────────
class FilterBar extends StatelessWidget {
  final Widget search;
  final List<Widget> pills;

  /// [ClearAllButton], sitting inline directly after the pills — not pushed
  /// to the far right.
  final Widget? clearAll;

  /// Right-aligned extras (Export, view toggle, result count…).
  final Widget? trailing;

  const FilterBar({
    super.key,
    required this.search,
    this.pills = const [],
    this.clearAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Search and the trailing actions stay pinned; the pill strip takes the
    // slack and scrolls horizontally when there are more filters than fit.
    // A plain Row here overflowed by ~550px on Sales at laptop widths.
    return SizedBox(
      height: kFilterRowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          search,
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Let the pills sit left and simply run off to the right when
              // the row is tight, rather than squeezing the search box.
              child: Row(
                children: [
                  for (var i = 0; i < pills.length; i++) ...[
                    SizedBox(width: i == 0 ? 12 : 10),
                    pills[i],
                  ],
                  if (clearAll != null) ...[
                    const SizedBox(width: 10),
                    clearAll!,
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

// ── Search field ────────────────────────────────────────────────────────────
class FilterSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final double width;

  const FilterSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Light theme gets a slightly deeper grey so the borderless box reads.
    final fill = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: colors.textHint,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.textHint,
            size: 18,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primaryOrange,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: fill,
        ),
      ),
    );
  }
}

// ── Shared pill chrome ──────────────────────────────────────────────────────
/// The rounded bordered capsule every pill shares.
class _PillShell extends StatelessWidget {
  final VoidCallback onTap;
  final List<Widget> children;
  const _PillShell({required this.onTap, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: kFilterPillHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: colors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// The dropdown panel every pill menu shares.
class _MenuPanel extends StatelessWidget {
  final List<Widget> children;
  const _MenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

TextStyle _pillLabelStyle(AppThemeColors colors) => TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: colors.textPrimary,
  fontFamily: 'Poppins',
);

// ── Multi-select pill ───────────────────────────────────────────────────────
/// Filter pill backed by an [RxSet] — opens a persistent checkbox menu that
/// stays open across taps, and shows a count badge once something is picked.
class MultiSelectFilterPill extends StatefulWidget {
  final String label;
  final RxSet<String> selected;
  final List<String> items;
  final ValueChanged<String> onToggle;
  final double menuWidth;

  const MultiSelectFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.items,
    required this.onToggle,
    this.menuWidth = 230,
  });

  @override
  State<MultiSelectFilterPill> createState() => _MultiSelectFilterPillState();
}

class _MultiSelectFilterPillState extends State<MultiSelectFilterPill> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => Positioned(
          width: widget.menuWidth,
          child: CompositedTransformFollower(
            link: _link,
            offset: const Offset(0, _kMenuOffset),
            child: TapRegion(
              onTapOutside: (_) => _overlayController.hide(),
              child: _MenuPanel(
                children: widget.items
                    .map(
                      (label) => Obx(() {
                        final checked = widget.selected.contains(label);
                        return InkWell(
                          onTap: () => widget.onToggle(label),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  checked
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 18,
                                  color: checked
                                      ? AppColors.primaryOrange
                                      : colors.textHint,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Poppins',
                                      color: colors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        child: _PillShell(
          onTap: _overlayController.toggle,
          children: [
            Icon(Icons.filter_alt_rounded, size: 15, color: colors.textPrimary),
            const SizedBox(width: 6),
            Text(widget.label, style: _pillLabelStyle(colors)),
            Obx(() {
              final count = widget.selected.length;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Single-select pill ──────────────────────────────────────────────────────
/// Filter/sort pill backed by a single value — opens a plain list menu.
/// Renders as `<label>: <value>`, or just `<value>` when [label] is null
/// (for values that already read as a label, e.g. "All Roles").
class SingleSelectFilterPill extends StatefulWidget {
  final String? label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final double menuWidth;

  const SingleSelectFilterPill({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon = Icons.filter_alt_rounded,
    this.menuWidth = 220,
  });

  /// Convenience for the standard "Sort by: X" pill.
  factory SingleSelectFilterPill.sort({
    Key? key,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double menuWidth = 220,
  }) => SingleSelectFilterPill(
    key: key,
    label: 'Sort by',
    value: value,
    items: items,
    onChanged: onChanged,
    icon: Icons.swap_vert_rounded,
    menuWidth: menuWidth,
  );

  @override
  State<SingleSelectFilterPill> createState() => _SingleSelectFilterPillState();
}

class _SingleSelectFilterPillState extends State<SingleSelectFilterPill> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => Positioned(
          width: widget.menuWidth,
          child: CompositedTransformFollower(
            link: _link,
            offset: const Offset(0, _kMenuOffset),
            child: TapRegion(
              onTapOutside: (_) => _overlayController.hide(),
              child: _MenuPanel(
                children: widget.items.map((option) {
                  final selected = widget.value == option;
                  return InkWell(
                    onTap: () {
                      widget.onChanged(option);
                      _overlayController.hide();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryOrange
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        child: _PillShell(
          onTap: _overlayController.toggle,
          children: [
            Icon(widget.icon, size: 16, color: colors.textPrimary),
            const SizedBox(width: 6),
            Text(
              widget.label == null
                  ? widget.value
                  : '${widget.label}: ${widget.value}',
              style: _pillLabelStyle(colors),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clear all ───────────────────────────────────────────────────────────────
/// Right-aligned "Clear all" — same pill chrome as the filter pills.
class ClearAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const ClearAllButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _PillShell(
      onTap: onTap,
      children: [
        Icon(Icons.close_rounded, size: 15, color: colors.textPrimary),
        const SizedBox(width: 6),
        Text('Clear all', style: _pillLabelStyle(colors)),
      ],
    );
  }
}
