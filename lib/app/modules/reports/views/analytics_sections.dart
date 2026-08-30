import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/donut_chart.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/widgets/analytics_charts.dart';
import 'package:shc_stock/app/modules/reports/widgets/analytics_panels.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Every panel on the Analytics tab, defined once. The web layout arranges them
// in rows, the mobile layout stacks the same widgets in one column — so a fix
// to a chart lands on both without being copied.
// ─────────────────────────────────────────────────────────────────────────────

const Color kAnalyticsGreen = Color(0xFF16A34A);
const Color kAnalyticsPurple = Color(0xFF7C6BE8);
const Color kAnalyticsRed = Color(0xFFEF4444);
const Color kAnalyticsAmber = Color(0xFFB45309);

/// Trend percentage as the stat card wants it — empty when the backend had no
/// baseline, so the card draws nothing rather than a made-up 0%.
String _trend(double? value) =>
    value == null ? '' : '${value.abs().toStringAsFixed(1)}%';

/// The four KPI cards along the top, in display order.
List<Widget> analyticsStatCards(BuildContext context, AnalyticsController c) {
  final accent = context.appColors.accent;
  return [
    // Same treatment as every other page's KPI row: rupee totals take the
    // smaller value size, and the trend shows the percentage on its own.
    AppStatCard(
      label: 'Total Sales',
      value: formatRupees(c.totalSales.value),
      icon: Icons.payments_outlined,
      iconColor: accent,
      trend: _trend(c.totalSalesTrend.value),
      trendUp: (c.totalSalesTrend.value ?? 0) >= 0,
      smallValue: true,
      showCaption: false,
    ),
    AppStatCard(
      label: 'Total Purchases',
      value: formatRupees(c.totalPurchases.value),
      icon: Icons.shopping_cart_outlined,
      iconColor: AppColors.primaryOrange,
      trend: _trend(c.totalPurchasesTrend.value),
      trendUp: (c.totalPurchasesTrend.value ?? 0) >= 0,
      smallValue: true,
      showCaption: false,
    ),
    AppStatCard(
      label: 'Active Clients',
      value: '${c.activeClients.value}',
      icon: Icons.groups_outlined,
      iconColor: kAnalyticsGreen,
      trend: _trend(c.activeClientsTrend.value),
      trendUp: (c.activeClientsTrend.value ?? 0) >= 0,
      showCaption: false,
    ),
    AppStatCard(
      label: 'Invoices Raised',
      value: '${c.invoicesRaised.value}',
      icon: Icons.receipt_long_outlined,
      iconColor: kAnalyticsPurple,
      trend: _trend(c.invoicesTrend.value),
      trendUp: (c.invoicesTrend.value ?? 0) >= 0,
      showCaption: false,
    ),
  ];
}

// ── Row 2 ────────────────────────────────────────────────────────────────────

class SalesVsPurchasesPanel extends GetView<AnalyticsController> {
  const SalesVsPurchasesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.appColors.accent;
    return AnalyticsPanel(
      title: 'Sales vs Purchases (12 months)',
      footer: AnalyticsLegend(
        entries: [('Sales', AppColors.primaryOrange), ('Purchases', accent)],
      ),
      child: Obx(
        () => DualLineChart(
          data: controller.salesVsPurchases.toList(),
          salesColor: AppColors.primaryOrange,
          purchaseColor: accent,
          valueFormatter: formatRupeesCompact,
        ),
      ),
    );
  }
}

class TopProductsPanel extends GetView<AnalyticsController> {
  const TopProductsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsPanel(
      title: 'Top Selling Products',
      child: Obx(() => RankedBarList(rows: controller.topProducts.toList())),
    );
  }
}

class TopClientsPanel extends GetView<AnalyticsController> {
  const TopClientsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsPanel(
      title: 'Top Clients by Revenue',
      child: Obx(() => RankedBarList(rows: controller.topClients.toList())),
    );
  }
}

// ── Row 3 ────────────────────────────────────────────────────────────────────

class StockMovementPanel extends GetView<AnalyticsController> {
  const StockMovementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.appColors.accent;
    return AnalyticsPanel(
      title: 'Stock Movement (Inflow vs Outflow)',
      subtitle: 'Units received from purchases vs dispatched via sales',
      footer: AnalyticsLegend(
        entries: [
          ('Inflow (Purchases)', accent),
          ('Outflow (Sales)', AppColors.primaryOrange),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(
          () => GroupedBarChart(
            data: controller.stockMovement.toList(),
            inflowColor: accent,
            outflowColor: AppColors.primaryOrange,
            height: constraints.maxHeight,
          ),
        ),
      ),
    );
  }
}

class InventoryHealthPanel extends GetView<AnalyticsController> {
  final double donutSize;

  const InventoryHealthPanel({super.key, this.donutSize = 130});

  @override
  Widget build(BuildContext context) {
    return AnalyticsPanel(
      title: 'Inventory Health',
      subtitle: 'Distribution of items by stock status',
      child: Obx(() {
        final total =
            controller.inStock.value +
            controller.lowStock.value +
            controller.outOfStock.value;
        if (total == 0) {
          return Center(
            child: Text(
              'No products yet',
              style: TextStyle(
                fontSize: 12.5,
                color: context.appColors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          );
        }

        CategorySlice slice(String label, int count, Color color) {
          final percent = count / total * 100;
          return CategorySlice(
            label: label,
            percent: percent,
            color: color,
            legendText: '$label   $count',
            tooltipText: '$count items · ${percent.toStringAsFixed(0)}%',
          );
        }

        return CategoryDonutChart(
          size: donutSize,
          slices: [
            slice('In Stock', controller.inStock.value, kAnalyticsGreen),
            slice(
              'Low Stock',
              controller.lowStock.value,
              AppColors.primaryOrange,
            ),
            slice('Out of Stock', controller.outOfStock.value, kAnalyticsRed),
          ],
        );
      }),
    );
  }
}

class PaymentCollectionPanel extends GetView<AnalyticsController> {
  const PaymentCollectionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return AnalyticsPanel(
      title: 'Payment Collection Rate',
      subtitle: 'Share of invoiced value already realised',
      child: Obx(
        () => Column(
          children: [
            Expanded(
              child: Center(
                child: HalfGauge(
                  percent: controller.collectionRate.value,
                  color: kAnalyticsGreen,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _amountBlock(
                    context,
                    'Collected',
                    formatRupees(controller.collected.value),
                    kAnalyticsGreen,
                    CrossAxisAlignment.start,
                  ),
                ),
                Expanded(
                  child: _amountBlock(
                    context,
                    'Outstanding',
                    formatRupees(controller.outstanding.value),
                    kAnalyticsRed,
                    CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountBlock(
    BuildContext context,
    String label,
    String value,
    Color color,
    CrossAxisAlignment align,
  ) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textHint,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

// ── Row 4 ────────────────────────────────────────────────────────────────────

class ReceivablesAgingPanel extends GetView<AnalyticsController> {
  const ReceivablesAgingPanel({super.key});

  /// Fresh money is green and ages through to red — the same reading order as
  /// the buckets themselves.
  static const List<Color> bucketColors = [
    kAnalyticsGreen,
    AppColors.primaryOrange,
    kAnalyticsAmber,
    kAnalyticsRed,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnalyticsPanel(
        title: 'Receivables Aging',
        expandChild: false,
        subtitle:
            'Share of ${formatRupeesCompact(controller.agingTotal.value)} '
            'outstanding by age bucket',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StackedShareBar(
              buckets: controller.agingBuckets.toList(),
              colors: bucketColors,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < controller.agingBuckets.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _legendRow(i)),
                    const SizedBox(width: 24),
                    Expanded(
                      child: i + 1 < controller.agingBuckets.length
                          ? _legendRow(i + 1)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(int i) {
    final bucket = controller.agingBuckets[i];
    final color = bucketColors[i % bucketColors.length];
    return LabelledAmount(
      label: bucket.label,
      amount: formatRupees(bucket.amount),
      dotColor: color,
      amountColor: i == 3 ? kAnalyticsRed : null,
    );
  }
}

class RevenueByCategoryPanel extends GetView<AnalyticsController> {
  const RevenueByCategoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnalyticsPanel(
        title: 'Revenue by Category',
        expandChild: false,
        subtitle:
            'Proportional share of '
            '${formatRupeesCompact(controller.categoryTotal.value)} in sales',
        // The treemap paints into whatever box it gets, so it needs an
        // explicit one in a panel that otherwise sizes to its content.
        child: SizedBox(
          height: 178,
          child: RevenueTreemap(rows: controller.categoryRevenue.toList()),
        ),
      ),
    );
  }
}

// ── Row 5 ────────────────────────────────────────────────────────────────────

class MonthComparisonPanel extends GetView<AnalyticsController> {
  const MonthComparisonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = colors.accent;

    return Obx(() {
      final growth = controller.monthGrowth.value;
      final up = (growth ?? 0) >= 0;
      final growthColor = growth == null
          ? colors.textSecondary
          : (up ? kAnalyticsGreen : kAnalyticsRed);

      return AnalyticsPanel(
        title: 'Sales This Month vs Last',
        expandChild: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TintedFigureTile(
                    value: formatRupeesCompact(controller.salesThisMonth.value),
                    caption: 'This Month',
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TintedFigureTile(
                    value: formatRupeesCompact(controller.salesLastMonth.value),
                    caption: 'Last Month',
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: growthColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (growth != null)
                    Icon(
                      up
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: growthColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    growth == null
                        ? 'No sales last month to compare against'
                        : '${growth.abs().toStringAsFixed(1)}% '
                              '${up ? 'growth' : 'decline'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: growthColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TintedFigureTile(
                    value: '${controller.ordersThisMonth.value}',
                    caption: 'Orders This Month',
                    color: kAnalyticsPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TintedFigureTile(
                    value: formatRupeesCompact(
                      controller.avgOrderValueThisMonth.value,
                    ),
                    caption: 'Avg. Order Value',
                    color: kAnalyticsRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class HealthIndicatorsPanel extends GetView<AnalyticsController> {
  /// One column on a phone, two side by side on the web.
  final int columns;

  const HealthIndicatorsPanel({super.key, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tiles = controller.indicators.toList();
      return AnalyticsPanel(
        title: 'Business Health Indicators',
        expandChild: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i += columns)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                // IntrinsicHeight, not a bare stretched Row: this panel sizes
                // to its content, so the row has no height to stretch into —
                // measuring the taller tile is what levels the pair.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var j = 0; j < columns; j++) ...[
                        if (j > 0) const SizedBox(width: 10),
                        Expanded(
                          child: i + j < tiles.length
                              ? IndicatorTile(indicator: tiles[i + j])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
