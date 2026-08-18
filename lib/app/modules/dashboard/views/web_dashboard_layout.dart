import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/bar_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/donut_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/sales_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/recent_transactions.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/low_stock_table.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/incoming_deliveries.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/category_breakdown.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/notes_todo.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/notes_dialog.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

class WebDashboardLayout extends StatelessWidget {
  const WebDashboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DashboardController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, c),
                Expanded(
                  // Obx: the page used to read the controller's lists straight
                  // out of build(), with no reactive wrapper anywhere — so it
                  // rendered whatever had arrived by the time some *unrelated*
                  // rebuild happened (a theme switch, a hover) and showed
                  // nothing at all when the fetch landed after the first
                  // frame. Every observable this page draws is touched below
                  // so the whole body redraws the moment the API answers.
                  child: Obx(() {
                    c.dashboardStats.length;
                    c.purchasesData.length;
                    c.salesData.length;
                    c.newClientsData.length;
                    c.categorySlices.length;
                    c.recentTransactions.length;
                    c.incomingDeliveries.length;
                    c.lowStockAlerts.length;
                    c.notes.length;
                    c.purchasesChange.value;
                    c.salesChange.value;
                    c.newClientsChange.value;

                    // First load only: the top bar stays, the body loads —
                    // a later refetch keeps the current numbers on screen
                    // instead of flashing back to a spinner.
                    if (c.isLoading.value && c.dashboardStats.isEmpty) {
                      return const AppLoadingIndicator(
                        label: 'Loading dashboard...',
                        padding: 120,
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: c.dashboardStats.asMap().entries.map((e) {
                              final isLast =
                                  e.key == c.dashboardStats.length - 1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: isLast ? 0 : 16,
                                  ),
                                  child: _DashboardStatTile(data: e.value),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPurchasesChart(context, c)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildSalesChart(context, c)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildNewClientsChart(context, c),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildCategoryDonut(context, c)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 65,
                                  child: _buildRecentTransactions(context, c),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 35,
                                  child: _buildIncomingDeliveries(context, c),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildCategoryBreakdown(context, c),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildLowStockAlerts(context, c),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _buildNotesTodo(context, c)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar: greeting + search + bell + avatar ───────────────────────────
  Widget _buildTopBar(BuildContext context, DashboardController c) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, ${c.greetingName}!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Here's what's happening in your inventory today",
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const HeaderSearchBox(),
          const SizedBox(width: 14),
          const HeaderActionsCluster(),
        ],
      ),
    );
  }

  // ── Charts ────────────────────────────────────────────────────────────────
  Widget _buildPurchasesChart(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'Purchases (6 months)',
      changeText: c.purchasesChange.value,
      child: SimpleBarChart(
        data: c.purchasesData,
        barColor: AppColors.primaryPurple,
        height: 150,
        valueFormatter: formatRupees,
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'Sales (6 months)',
      changeText: c.salesChange.value,
      child: SimpleBarChart(
        data: c.salesData,
        barColor: AppColors.primaryOrange,
        height: 150,
        valueFormatter: formatRupees,
      ),
    );
  }

  Widget _buildNewClientsChart(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'New clients (6 months)',
      changeText: c.newClientsChange.value,
      child: SizedBox(
        height: 150,
        child: SalesLineChart(
          data: c.newClientsData,
          lineColor: context.appColors.accent,
          valueFormatter: _clientCount,
        ),
      ),
    );
  }

  /// Hover-tooltip wording for the New clients line — the series is a count,
  /// not an amount, so it must not go through the rupee formatter.
  static String _clientCount(double v) {
    final n = v.round();
    return n == 1 ? '1 new client' : '$n new clients';
  }

  Widget _buildCategoryDonut(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'Sales by category',
      child: SizedBox(
        height: 150,
        child: Center(
          child: CategoryDonutChart(slices: c.categorySlices, size: 120),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, DashboardController c) {
    return _SectionCard(
      title: 'Recent transactions',
      child: RecentTransactions(transactions: c.recentTransactions),
    );
  }

  Widget _buildIncomingDeliveries(BuildContext context, DashboardController c) {
    return _SectionCard(
      title: 'Incoming deliveries',
      child: IncomingDeliveries(
        deliveries: c.incomingDeliveries,
        onToggle: c.toggleDeliveryDone,
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, DashboardController c) {
    return _SectionCard(
      title: 'Category breakdown',
      child: CategoryBreakdown(categories: c.categorySlices),
    );
  }

  Widget _buildLowStockAlerts(BuildContext context, DashboardController c) {
    return _SectionCard(
      title: 'Low stock alerts',
      child: LowStockTable(items: c.lowStockAlerts),
    );
  }

  Widget _buildNotesTodo(BuildContext context, DashboardController c) {
    return _SectionCard(
      title: 'Notes & to-dos',
      trailing: TextButton(
        onPressed: () => Get.dialog(
          NotesDialog(notes: c.notes, onToggle: c.toggleNote, onAdd: c.addNote),
        ),
        child: const Text(
          'View All',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryOrange,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      child: NotesTodo(
        notes: c.notes,
        onToggle: c.toggleNote,
        onAdd: c.addNote,
      ),
    );
  }
}

// ── Pastel summary tile ────────────────────────────────────────────────────
/// The dashboard's five summary tiles are the same card every other page's
/// KPI row uses — icon boxed on the left, flat tint, no border or shadow.
class _DashboardStatTile extends StatelessWidget {
  final DashboardStatData data;
  const _DashboardStatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppStatCard(
      label: data.title,
      value: data.value,
      icon: data.icon,
      iconColor: data.iconColor,
      trend: data.change ?? '',
      trendUp: data.isPositive,
      showCaption: false,
    );
  }
}

// ── Generic card wrapper for lists/tables ─────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title flexes so a long one plus a trailing action can't
          // overflow the card at laptop widths.
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Chart card: title + chart + trailing change caption ───────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String? changeText;
  final Widget child;

  const _ChartCard({required this.title, this.changeText, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 10),
          // Always reserve the caption line's space (invisible when absent)
          // so all 4 cards share the same height without a hardcoded value.
          Visibility(
            visible: changeText != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              changeText ?? '',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2FA85C),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
