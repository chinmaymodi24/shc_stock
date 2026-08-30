import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Height of the horizontally-scrolling KPI strip on the mobile list pages.
///
/// The strip is a fixed height rather than an `IntrinsicHeight` because the
/// card's inner `Row` has an `Expanded` child, and intrinsic-height measuring
/// through a flex child reports a value that doesn't match the real layout —
/// so the tallest card (a 2-line label like "Total Products") grew past the
/// others. Sized for that worst case: 36px vertical padding + a two-line
/// label, its 4px gap, and the value line.
const double kMobileStatStripHeight = 108;

// ─────────────────────────────────────────────────────────────────────────────
// The app's summary card — one design, used by every page's KPI row.
//
// It used to be three widgets (a flat tinted pill, an icon+trend+sparkline
// surface card, and a no-trend simple card) with per-page tuning knobs for
// padding, icon size, fonts, gaps, shadows and sparkline geometry. Products
// and Transactions ended up with no icon at all, and every page read slightly
// differently. That is now collapsed into the Clients-page design: a flat
// tinted card, no border, no shadow, icon boxed on the LEFT of the label and
// value, optional trend line underneath.
//
// Sizing is deliberately NOT parameterised — the whole point is that a card
// looks the same on Products as it does on Sales.
// ─────────────────────────────────────────────────────────────────────────────

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  /// Drives the whole card: the icon, the label color and (unless [cardBg]
  /// overrides it) the card's tint.
  final Color iconColor;

  /// Trend line under the value — empty means the API had no baseline to
  /// compare against, and nothing is drawn rather than a made-up percentage.
  final String trend;
  final bool trendUp;

  /// Shrinks the value text for the long ones (rupee totals, product names).
  final bool smallValue;

  /// Appends [captionText] after the trend percentage.
  final bool showCaption;

  /// What the caption after the trend reads. Analytics compares against a
  /// quarter for some cards, so the period isn't always "last month".
  final String captionText;

  /// Card tint override. Defaults to a 10% wash of [iconColor].
  final Color? cardBg;

  /// Tightens padding, icon and type — for the phone grid, where two cards
  /// share the row and the full-size card reads oversized.
  final bool dense;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trend = '',
    this.trendUp = true,
    this.smallValue = false,
    this.showCaption = true,
    this.captionText = 'from last month',
    this.cardBg,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final trendColor = trendUp
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.all(dense ? 11 : 18),
      decoration: BoxDecoration(
        color: cardBg ?? iconColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        // No border, no shadow — the tint alone separates the card from the
        // page.
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Centre the content when the card is taller than it needs to be —
        // the fixed-height mobile strip stretches every card to the tallest
        // one's height, and without this the shorter cards' text stuck to the
        // top with dead space underneath.
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: dense ? 30 : 40,
                height: dense ? 30 : 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(dense ? 8 : 10),
                ),
                child: Icon(icon, color: iconColor, size: dense ? 16 : 20),
              ),
              SizedBox(width: dense ? 9 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      // Two lines: long labels ("Total Transactions (This
                      // Month)") and narrow phone cards would otherwise be
                      // cut mid-word.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 10.5 : 12,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withValues(alpha: 0.8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: dense ? 1 : 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense
                            ? 15
                            : smallValue
                            ? 18
                            : 26,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trendUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    trend,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (showCaption) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      captionText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web KPI row — the row of [AppStatCard]s at the top of every desktop page.
// The cards share the row's full width evenly, with a common height. Capping
// the width was tried and reverted: it left a wide empty gutter on the pages
// with fewer cards, which reads far worse than the cards simply being a little
// wider there.
// ─────────────────────────────────────────────────────────────────────────────
class AppStatCardRow extends StatelessWidget {
  final List<Widget> cards;
  final double gap;

  const AppStatCardRow({super.key, required this.cards, this.gap = 16});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight so `stretch` has a bounded height to work with (the row
    // lives in a scroll view) — every card in the row ends up the same height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile KPI strip — the horizontally-scrolling row of summary cards at the
// top of every mobile list page. One widget, so a change lands on all pages
// at once instead of being copy-pasted per screen.
// ─────────────────────────────────────────────────────────────────────────────

/// One card in a [MobileStatStrip].
class MobileStatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// When set, the card becomes tappable (e.g. a stat card that also acts as
  /// a quick filter).
  final VoidCallback? onTap;

  /// Draws a coloured ring around the card — used to show a tap-filter card
  /// is currently the active filter.
  final bool selected;

  const MobileStatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.selected = false,
  });
}

/// One card in the strip — plain [AppStatCard], plus an [InkWell] + selected
/// ring when the data carries an `onTap`.
class _StripCard extends StatelessWidget {
  final MobileStatCardData data;

  /// The grid's cards are tighter than the strip's — two share a phone row.
  final bool dense;

  const _StripCard({required this.data, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final radius = dense ? 12.0 : 14.0;
    final card = AppStatCard(
      label: data.label,
      value: data.value,
      icon: data.icon,
      iconColor: data.color,
      smallValue: true,
      showCaption: false,
      dense: dense,
    );
    if (data.onTap == null) return card;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: data.selected ? data.color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: card,
      ),
    );
  }
}

/// The same cards laid out two-per-row instead of in a scrolling strip, so
/// every KPI is visible at once without a sideways swipe. Rows size to their
/// tallest card, and each pair splits the width evenly.
class MobileStatGrid extends StatelessWidget {
  final List<MobileStatCardData> cards;
  final EdgeInsets padding;
  final double gap;

  const MobileStatGrid({
    super.key,
    required this.cards,
    this.padding = EdgeInsets.zero,
    this.gap = 10,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final left = cards[i];
      final right = i + 1 < cards.length ? cards[i + 1] : null;
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StripCard(data: left, dense: true)),
              SizedBox(width: gap),
              // An odd card keeps its half-width so it lines up with the
              // column above rather than stretching across the row.
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _StripCard(data: right, dense: true),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class MobileStatStrip extends StatelessWidget {
  final List<MobileStatCardData> cards;

  /// Padding around the scrolling row (e.g. the page's 16px side gutter).
  /// Its vertical part is added to the strip height so the cards themselves
  /// stay exactly [kMobileStatStripHeight] tall.
  final EdgeInsets padding;

  /// Fixed width of each card — 150 everywhere so the strip reads the same
  /// on every page.
  static const double cardWidth = 150;

  const MobileStatStrip({
    super.key,
    required this.cards,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMobileStatStripHeight + padding.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        // stretch → every card fills the fixed strip height, so a 2-line
        // label ("Total Products") no longer leaves the others shorter.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(
                width: cardWidth,
                child: _StripCard(data: cards[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
