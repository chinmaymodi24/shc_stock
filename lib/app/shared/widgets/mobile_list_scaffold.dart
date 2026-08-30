import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The shared body for every mobile list page. One CustomScrollView so:
//   • the KPI cards (2×2 grid, one shared height everywhere) scroll away with
//     the list and come back when you reach the top,
//   • the search field — and any extra filter control (Sales' tab chips) —
//     stays pinned so it's reachable from anywhere in the list,
//   • an optional "Showing N …" line scrolls with the list.
// A scroll/pin fix here lands on every list page at once.
// ─────────────────────────────────────────────────────────────────────────────

class MobileListScaffold extends StatelessWidget {
  final List<MobileStatCardData> statCards;

  /// The search field (a [FilterSearchField]); the 16/12/16 padding around it
  /// is added here so callers just pass the field.
  final Widget search;

  /// Extra control pinned under the search field — e.g. Sales' status tabs.
  final Widget? pinnedExtra;

  /// Its rendered height, so the pinned header can size itself. Ignored when
  /// [pinnedExtra] is null.
  final double pinnedExtraHeight;

  /// A short "Showing 12 clients" line under the pinned bar; scrolls away.
  final String? countLabel;

  /// The list itself — a `SliverList`, `SliverPadding`, `SliverFillRemaining`…
  final Widget sliver;

  const MobileListScaffold({
    super.key,
    required this.statCards,
    required this.search,
    required this.sliver,
    this.pinnedExtra,
    this.pinnedExtraHeight = 0,
    this.countLabel,
  });

  // Search field (~40) + 12 top / 10 bottom padding.
  static const double _searchRow = 62;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasExtra = pinnedExtra != null;
    final pinnedHeight = _searchRow + (hasExtra ? pinnedExtraHeight + 10 : 0);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: MobileStatGrid(
            cards: statCards,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedBar(
            height: pinnedHeight,
            background: colors.background,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, hasExtra ? 0 : 10),
              child: hasExtra
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        search,
                        const SizedBox(height: 10),
                        pinnedExtra!,
                      ],
                    )
                  : search,
            ),
          ),
        ),
        if (countLabel != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                countLabel!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        sliver,
      ],
    );
  }
}

class _PinnedBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;
  final double height;
  const _PinnedBar({
    required this.child,
    required this.background,
    required this.height,
  });

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Container(color: background, height: height, child: child);

  @override
  bool shouldRebuild(_PinnedBar old) =>
      old.child != child ||
      old.background != background ||
      old.height != height;
}

/// The centered "no results" block every list page shows, as a sliver that
/// fills the remaining viewport.
class MobileListEmpty extends StatelessWidget {
  final IconData icon;
  final String label;
  const MobileListEmpty({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textHint),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: colors.textHint,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
