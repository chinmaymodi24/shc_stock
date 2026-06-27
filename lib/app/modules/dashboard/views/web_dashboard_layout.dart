import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/stat_card.dart';
import '../widgets/donut_chart.dart';
import '../widgets/sales_chart.dart';
import '../widgets/recent_transactions.dart';
import '../widgets/low_stock_table.dart';
import '../widgets/quick_action_button.dart';
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
                        _buildStatCards(c),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 45, child: _buildStockOverview(c)),
                              const SizedBox(width: 20),
                              Expanded(flex: 55, child: _buildRecentTransactions(c)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 45, child: _buildLowStockAlert(c)),
                              const SizedBox(width: 20),
                              Expanded(flex: 55, child: _buildSalesOverview(c)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                        const SizedBox(height: 16),
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

  Widget _buildTopBar(BuildContext context, DashboardController c) {
    final colors = context.appColors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider, width: 1)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Stack(
            children: [
              IconButton(icon: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 24), onPressed: () {}),
              Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 4),
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 20)),
          const SizedBox(width: 8),
          Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardController c) {
    return Row(
      children: c.webStatCards.asMap().entries.map((e) {
        final isLast = e.key == c.webStatCards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 16),
            child: StatCard(data: e.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockOverview(DashboardController c) {
    return _SectionCard(
      title: 'Stock Overview',
      child: DonutChart(inStock: c.inStockPercent, lowStock: c.lowStockPercent, outOfStock: c.outOfStockPercent, totalItems: c.totalItems),
    );
  }

  Widget _buildRecentTransactions(DashboardController c) {
    return _SectionCard(
      title: 'Recent Transactions',
      trailing: TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
      child: RecentTransactions(transactions: c.recentTransactions),
    );
  }

  Widget _buildLowStockAlert(DashboardController c) {
    return _SectionCard(
      title: 'Low Stock Alert',
      trailing: TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
      child: LowStockTable(items: c.lowStockItems),
    );
  }

  Widget _buildSalesOverview(DashboardController c) {
    return _SectionCard(
      title: 'Sales Overview',
      trailing: Obx(() => _DropdownFilter(value: c.selectedSalesFilter.value, items: c.salesFilters, onChanged: c.changeSalesFilter)),
      child: SizedBox(height: 220, child: SalesLineChart(data: c.salesChartData)),
    );
  }

  Widget _buildQuickActions() {
    return _SectionCard(
      title: 'Quick Actions',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          QuickActionTile(icon: Icons.shopping_cart_outlined, label: 'Add Sale'),
          QuickActionTile(icon: Icons.shopping_bag_outlined, label: 'Add Purchase'),
          QuickActionTile(icon: Icons.inventory_2_outlined, label: 'Add Product'),
          QuickActionTile(icon: Icons.warehouse_outlined, label: 'View Stock'),
        ],
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
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

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        value: value, isDense: true, underline: const SizedBox(),
        dropdownColor: colors.surface,
        style: TextStyle(fontSize: 12, color: colors.textPrimary, fontFamily: 'Poppins'),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}
