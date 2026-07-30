import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_models.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/web_top_bar.dart';
import '../widgets/bar_chart.dart';
import '../widgets/donut_chart.dart';
import '../widgets/sales_chart.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/low_stock_table.dart';
import '../widgets/incoming_deliveries.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/notes_todo.dart';
import '../widgets/notes_dialog.dart';
import '../../../core/theme/app_colors.dart';

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: c.dashboardStats.asMap().entries.map((e) {
                            final isLast = e.key == c.dashboardStats.length - 1;
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
                            Expanded(child: _buildNewClientsChart(context, c)),
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
                              Expanded(child: _buildLowStockAlerts(context, c)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildNotesTodo(context, c)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
      changeText: c.purchasesChange,
      child: SimpleBarChart(
        data: c.purchasesData,
        barColor: AppColors.primaryPurple,
        height: 150,
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'Sales (6 months)',
      changeText: c.salesChange,
      child: SimpleBarChart(
        data: c.salesData,
        barColor: AppColors.primaryOrange,
        height: 150,
      ),
    );
  }

  Widget _buildNewClientsChart(BuildContext context, DashboardController c) {
    return _ChartCard(
      title: 'New clients (6 months)',
      changeText: c.newClientsChange,
      child: SizedBox(
        height: 150,
        child: SalesLineChart(
          data: c.newClientsData,
          lineColor: AppColors.accentPurple,
        ),
      ),
    );
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
      child: IncomingDeliveries(deliveries: c.incomingDeliveries),
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
class _DashboardStatTile extends StatelessWidget {
  final DashboardStatData data;
  const _DashboardStatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: data.bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.iconColor, size: 20),
          const SizedBox(height: 10),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: data.iconColor.withValues(alpha: 0.85),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1240),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          // Always reserve the caption line's space (invisible when there's
          // no change value) so every tile is the same height naturally,
          // without hardcoding a height that can drift out of sync with
          // actual (async-loaded web font) text metrics.
          Visibility(
            visible: data.change != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              data.change ?? '',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              if (trailing != null) trailing!,
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
