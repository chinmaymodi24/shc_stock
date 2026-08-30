import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/bar_chart.dart';
import 'package:shc_stock/app/modules/reports/controllers/profit_loss_controller.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';
import 'package:shc_stock/app/modules/reports/views/analytics_sections.dart';
import 'package:shc_stock/app/modules/reports/widgets/analytics_panels.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Profit & Loss.
//
// Revenue and cost of goods both come off the sale lines, so the margin here
// is the real one. Operating expenses aren't modelled anywhere in the system,
// which is why the statement stops at gross profit and says so rather than
// printing a net line it can't stand behind.
//
// One body for both form factors: [compact] stacks the summary cards and drops
// the two middle table columns on a phone.
// ─────────────────────────────────────────────────────────────────────────────
class ProfitLossTab extends GetView<ProfitLossController> {
  final bool compact;

  const ProfitLossTab({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gutter = compact ? 16.0 : 24.0;

    return Obx(() {
      if (controller.isLoading.value) {
        return AppLoadingIndicator(
          label: 'Loading profit & loss...',
          padding: compact ? 90 : 120,
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summary(context),
            const SizedBox(height: 16),
            SizedBox(
              height: compact ? 230 : 250,
              child: AnalyticsPanel(
                title: compact
                    ? 'Gross Profit by Month (6 months)'
                    : 'Gross Profit by Month (12 months)',
                subtitle: 'Revenue less cost of goods sold',
                // LayoutBuilder runs its builder after the surrounding Obx has
                // closed its tracking scope, so the read has to happen inside.
                child: LayoutBuilder(
                  builder: (context, constraints) => Obx(
                    () => SimpleBarChart(
                      height: constraints.maxHeight,
                      barColor: kAnalyticsGreen,
                      valueFormatter: formatRupeesCompact,
                      // Twelve bars on a phone squeeze the month labels down
                      // to "Se" / "Oc"; half as many stay readable, and the
                      // statement below still lists all twelve.
                      data: [
                        for (final m in _chartMonths())
                          ChartPoint(label: m.label, value: m.grossProfit),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _statement(context),
            const SizedBox(height: 16),
            _contribution(context),
            const SizedBox(height: 12),
            Text(
              'Operating expenses (salaries, rent, freight, taxes) are not '
              'recorded in the system, so this statement stops at gross '
              'profit — it is not a net profit figure.',
              style: TextStyle(
                fontSize: 11.5,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Months the bar chart plots — all twelve on the web, the most recent six
  /// on a phone.
  List<ProfitLossMonth> _chartMonths() {
    final all = controller.months.toList();
    if (!compact || all.length <= 6) return all;
    return all.sublist(all.length - 6);
  }

  // ── Summary cards ──────────────────────────────────────────────────────────

  Widget _summary(BuildContext context) {
    final cards = [
      AppStatCard(
        label: 'Revenue (12 months)',
        value: formatRupees(controller.revenue.value),
        icon: Icons.payments_outlined,
        iconColor: context.appColors.accent,
      ),
      AppStatCard(
        label: 'Cost of Goods Sold',
        value: formatRupees(controller.cogs.value),
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.primaryOrange,
      ),
      AppStatCard(
        label: 'Gross Profit',
        value: formatRupees(controller.grossProfit.value),
        icon: Icons.trending_up_rounded,
        iconColor: kAnalyticsGreen,
      ),
      AppStatCard(
        label: 'Gross Margin',
        value: '${controller.marginPct.value.toStringAsFixed(1)}%',
        icon: Icons.percent_rounded,
        iconColor: kAnalyticsPurple,
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            cards[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  // ── Monthly statement ──────────────────────────────────────────────────────

  Widget _statement(BuildContext context) {
    final colors = context.appColors;
    return AnalyticsPanel(
      title: 'Monthly Statement',
      subtitle: 'Last 12 months, oldest first',
      expandChild: false,
      child: Column(
        children: [
          _statementRow(
            context,
            'Month',
            'Revenue',
            'COGS',
            'Gross Profit',
            'Margin',
            header: true,
          ),
          Divider(height: 12, color: colors.divider),
          for (final m in controller.months)
            _statementRow(
              context,
              m.label,
              formatRupeesCompact(m.revenue),
              formatRupeesCompact(m.cogs),
              formatRupeesCompact(m.grossProfit),
              '${m.marginPct.toStringAsFixed(1)}%',
              positive: m.grossProfit >= 0,
            ),
          Divider(height: 12, color: colors.divider),
          _statementRow(
            context,
            'Total',
            formatRupeesCompact(controller.revenue.value),
            formatRupeesCompact(controller.cogs.value),
            formatRupeesCompact(controller.grossProfit.value),
            '${controller.marginPct.value.toStringAsFixed(1)}%',
            header: true,
          ),
        ],
      ),
    );
  }

  Widget _statementRow(
    BuildContext context,
    String month,
    String revenue,
    String cogs,
    String gross,
    String margin, {
    bool header = false,
    bool positive = true,
  }) {
    final colors = context.appColors;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: header ? FontWeight.w700 : FontWeight.w500,
      color: header ? colors.textPrimary : colors.textSecondary,
      fontFamily: 'Poppins',
    );

    Widget cell(String text, {int flex = 2, Color? color, bool right = true}) =>
        Expanded(
          flex: flex,
          child: Text(
            text,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: color == null ? style : style.copyWith(color: color),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          cell(month, flex: 2, right: false, color: colors.textPrimary),
          // A phone can't hold five money columns; revenue and COGS give way
          // to the two figures the page is actually about.
          if (!compact) ...[cell(revenue), cell(cogs)],
          cell(
            gross,
            color: header
                ? colors.textPrimary
                : (positive ? kAnalyticsGreen : kAnalyticsRed),
          ),
          cell(margin, flex: 1),
        ],
      ),
    );
  }

  // ── Per-product contribution ───────────────────────────────────────────────

  Widget _contribution(BuildContext context) {
    final colors = context.appColors;
    final rows = controller.topProducts;

    return AnalyticsPanel(
      title: 'Profit Contribution by Product',
      subtitle: 'Biggest contributors to gross profit',
      expandChild: false,
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No sales recorded yet',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (final p in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.product,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                '${formatRupeesCompact(p.revenue)} revenue · '
                                '${formatRupeesCompact(p.cogs)} cost',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textHint,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatRupeesCompact(p.grossProfit),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.grossProfit >= 0
                                    ? kAnalyticsGreen
                                    : kAnalyticsRed,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              '${p.marginPct.toStringAsFixed(1)}% margin',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
