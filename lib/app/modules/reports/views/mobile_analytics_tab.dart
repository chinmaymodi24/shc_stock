import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/views/analytics_sections.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Analytics on a phone: the same panels as the web tab, stacked in
// one column, with the four KPI figures in the shared horizontally-scrolling
// strip every mobile page uses.
//
// Chart panels carry explicit heights here too — a chart needs a box, and a
// scrolling column hands out an unbounded one.
// ─────────────────────────────────────────────────────────────────────────────
class MobileAnalyticsTab extends GetView<AnalyticsController> {
  const MobileAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const AppLoadingIndicator(
          label: 'Loading analytics...',
          padding: 90,
        );
      }

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileStatStrip(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              cards: [
                MobileStatCardData(
                  label: 'Total Sales',
                  value: formatRupeesCompact(controller.totalSales.value),
                  icon: Icons.payments_outlined,
                  color: context.appColors.accent,
                ),
                MobileStatCardData(
                  label: 'Total Purchases',
                  value: formatRupeesCompact(controller.totalPurchases.value),
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.primaryOrange,
                ),
                MobileStatCardData(
                  label: 'Active Clients',
                  value: '${controller.activeClients.value}',
                  icon: Icons.groups_outlined,
                  color: kAnalyticsGreen,
                ),
                MobileStatCardData(
                  label: 'Invoices Raised',
                  value: '${controller.invoicesRaised.value}',
                  icon: Icons.receipt_long_outlined,
                  color: kAnalyticsPurple,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(height: 210, child: SalesVsPurchasesPanel()),
                  SizedBox(height: 12),
                  SizedBox(height: 224, child: TopProductsPanel()),
                  SizedBox(height: 12),
                  SizedBox(height: 224, child: TopClientsPanel()),
                  SizedBox(height: 12),
                  SizedBox(height: 250, child: StockMovementPanel()),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 230,
                    child: InventoryHealthPanel(donutSize: 120),
                  ),
                  SizedBox(height: 12),
                  SizedBox(height: 250, child: PaymentCollectionPanel()),
                  SizedBox(height: 12),
                  ReceivablesAgingPanel(),
                  SizedBox(height: 12),
                  RevenueByCategoryPanel(),
                  SizedBox(height: 12),
                  MonthComparisonPanel(),
                  SizedBox(height: 12),
                  HealthIndicatorsPanel(columns: 1),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
