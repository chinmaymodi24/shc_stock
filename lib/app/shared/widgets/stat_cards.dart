import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

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

  /// Appends "from last month" after the trend percentage.
  final bool showCaption;

  /// Card tint override. Defaults to a 10% wash of [iconColor].
  final Color? cardBg;

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
    this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final trendColor = trendUp
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg ?? iconColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        // No border, no shadow — the tint alone separates the card from the
        // page.
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withValues(alpha: 0.8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: smallValue ? 18 : 26,
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
                      'from last month',
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
