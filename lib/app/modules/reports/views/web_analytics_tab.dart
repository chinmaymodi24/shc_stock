import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/views/analytics_sections.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Analytics, desktop arrangement.
//
// Five bands: the KPI cards, the trend + two ranked lists, the operational
// trio (stock movement / inventory health / collection rate), and then the
// financial pair-of-pairs — receivables and revenue mix over the
// month-comparison and health-indicator blocks.
//
// The chart bands get explicit heights because a chart has to be handed a box
// to paint into; the content-sized bands use IntrinsicHeight so the two panels
// beside each other always end level.
// ─────────────────────────────────────────────────────────────────────────────
class WebAnalyticsTab extends GetView<AnalyticsController> {
  const WebAnalyticsTab({super.key});

  /// Widths in each band, as flex units — taken from the reference layout.
  static const _trioFlex = [13, 10, 10];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoadingIndicator(
          label: 'Loading analytics...',
          padding: 120,
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStatCardRow(cards: analyticsStatCards(context, controller)),
            const SizedBox(height: 16),
            // 224 is what four ranked rows need under the panel header; the
            // line chart simply gets the leftover as its plot box.
            SizedBox(
              height: 224,
              child: _row(const [
                SalesVsPurchasesPanel(),
                TopProductsPanel(),
                TopClientsPanel(),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 236,
              child: _row(const [
                StockMovementPanel(),
                InventoryHealthPanel(),
                PaymentCollectionPanel(),
              ], flex: _trioFlex),
            ),
            const SizedBox(height: 24),
            // Fixed rather than IntrinsicHeight: both panels contain a
            // LayoutBuilder (the aging bar measures itself to place its
            // tooltip, the treemap to lay out its tiles), and IntrinsicHeight
            // cannot measure through one.
            SizedBox(
              height: 262,
              child: _row(const [
                ReceivablesAgingPanel(),
                RevenueByCategoryPanel(),
              ]),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: _row(const [
                MonthComparisonPanel(),
                HealthIndicatorsPanel(),
              ]),
            ),
          ],
        ),
      );
    });
  }

  /// Equal-width columns unless [flex] says otherwise, 16px apart.
  Widget _row(List<Widget> children, {List<int>? flex}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(flex: flex?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}
