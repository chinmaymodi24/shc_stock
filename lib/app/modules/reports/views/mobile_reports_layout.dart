import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/modules/reports/views/web_reports_layout.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';

/// Mobile counterpart of WebReportsLayout — same data (GET /api/stats/reports)
/// and the same ReportSectionCard/ReportRankCard, stacked single-column
/// instead of side-by-side rows.
class MobileReportsLayout extends GetView<ReportsController> {
  const MobileReportsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.reports),
      appBar: _buildAppBar(context),
      body: Obx(() {
        final loading = controller.isLoading.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rangeRow(context, colors),
              const SizedBox(height: 16),
              if (loading)
                const AppLoadingIndicator(
                  label: 'Loading reports...',
                  padding: 80,
                )
              else ...[
                ReportSectionCard(
                  title: 'Sales',
                  icon: Icons.trending_up_rounded,
                  accent: const Color(0xFF22C55E),
                  lines: controller.salesLines,
                  display: displayReportValue,
                ),
                const SizedBox(height: 12),
                ReportSectionCard(
                  title: 'Purchases',
                  icon: Icons.shopping_cart_outlined,
                  accent: AppColors.primaryOrange,
                  lines: controller.purchaseLines,
                  display: displayReportValue,
                ),
                const SizedBox(height: 12),
                ReportSectionCard(
                  title: 'Stock',
                  icon: Icons.inventory_2_outlined,
                  accent: context.appColors.accent,
                  lines: controller.stockLines,
                  display: displayReportValue,
                ),
                const SizedBox(height: 12),
                reportNetMovementCard(colors, controller),
                const SizedBox(height: 12),
                ReportRankCard(
                  title: 'Top Products',
                  subtitle: 'By units sold',
                  rows: controller.topProducts,
                  money: false,
                ),
                const SizedBox(height: 12),
                ReportRankCard(
                  title: 'Top Clients',
                  subtitle: 'By sales value',
                  rows: controller.topClients,
                  money: true,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Reports',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  Widget _rangeRow(BuildContext context, AppThemeColors colors) {
    final from = controller.from.value;
    final to = controller.to.value;
    final label = from == null || to == null
        ? 'All time'
        : '${reportDateFmt.format(from)} — ${reportDateFmt.format(to)}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (from != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: controller.clearRange,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'Poppins',
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => controller.pickRange(context),
          icon: const Icon(
            Icons.date_range_rounded,
            color: Colors.white,
            size: 16,
          ),
          label: const Text(
            'Range',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }
}
