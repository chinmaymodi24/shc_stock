import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The chrome the Analytics tab's charts sit inside — one panel shell, one
// legend, one indicator tile — so the web and mobile layouts stay identical
// apart from how they stack.
// ─────────────────────────────────────────────────────────────────────────────

/// A titled surface card. [child] gets whatever height is left after the
/// header, so a chart inside can size itself against the panel.
class AnalyticsPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  /// Legend row pinned under the chart (Sales / Purchases, Inflow / Outflow).
  final Widget? footer;
  final EdgeInsets padding;

  /// Whether [child] takes all the height left over. True for charts, which
  /// need a bounded box to paint into; false for panels made of stacked rows,
  /// which size themselves and can then sit in an IntrinsicHeight row.
  final bool expandChild;

  const AnalyticsPanel({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(16),
    this.expandChild = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11.5,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (expandChild) Expanded(child: child) else child,
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}

/// Dot legend under a chart.
class AnalyticsLegend extends StatelessWidget {
  final List<(String, Color)> entries;

  const AnalyticsLegend({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final (label, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// One cell of the Business Health Indicators grid.
class IndicatorTile extends StatelessWidget {
  final HealthIndicator indicator;

  const IndicatorTile({super.key, required this.indicator});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trendColor = indicator.neutral
        ? colors.textHint
        : (indicator.trendUp
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indicator.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            indicator.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (indicator.trend.isNotEmpty) ...[
                Icon(
                  indicator.trendUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Text(
                  indicator.trend,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  indicator.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Flat tinted tile — the four figures in "Sales This Month vs Last".
class TintedFigureTile extends StatelessWidget {
  final String value;
  final String caption;
  final Color color;

  const TintedFigureTile({
    super.key,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled amount under the receivables bar / beside the gauge.
class LabelledAmount extends StatelessWidget {
  final String label;
  final String amount;
  final Color? dotColor;
  final Color? amountColor;

  const LabelledAmount({
    super.key,
    required this.label,
    required this.amount,
    this.dotColor,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        if (dotColor != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: amountColor ?? colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
