import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/stat_card.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/today_sales_card.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/quick_action_button.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import '../widgets/app_drawer.dart';

class MobileDashboardLayout extends StatelessWidget {
  const MobileDashboardLayout({super.key});

  static const _quickActions = [
    _QA(icon: Icons.shopping_cart_outlined, label: 'Add Sale'),
    _QA(icon: Icons.shopping_bag_outlined, label: 'Add Purchase'),
    _QA(icon: Icons.inventory_2_outlined, label: 'Add Product'),
    _QA(icon: Icons.warehouse_outlined, label: 'View Stock'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DashboardController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.dashboard),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Sales big card
            const TodaySalesCard(),
            const SizedBox(height: 16),

            // 2x2 stat mini-cards
            Row(
              children: [
                Expanded(child: StatCard(data: c.webStatCards[0], compact: true)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(data: c.webStatCards[1], compact: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SimpleStatCard(label: 'Purchase (Today)', value: '₹ 40,000'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SimpleStatCard(label: 'Sales (This Month)', value: '₹ 18,75,000'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: _quickActions.map((qa) => QuickActionButton(icon: qa.icon, label: qa.label)).toList(),
            ),
            const SizedBox(height: 20),

            // Stock Summary
            Text('Stock Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.divider),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _StockSummaryRow(label: 'Total Products', value: '1,245', isFirst: true),
                  Divider(height: 1, color: colors.divider),
                  _StockSummaryRow(label: 'Low Stock Items', value: '23', valueColor: const Color(0xFFEF4444)),
                  Divider(height: 1, color: colors.divider),
                  _StockSummaryRow(label: 'Out of Stock', value: '65', valueColor: const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => _buildBottomNav(c)),
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
      title: Image.asset(
        "assets/logo.png",
        width: 80,
        height : 40,
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(icon: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 24), onPressed: () {}),
            Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ],
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: colors.divider)),
    );
  }

  Widget _buildBottomNav(DashboardController c) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
      _NavItem(icon: Icons.shopping_cart_outlined, label: 'Sales'),
      _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = c.selectedNavIndex.value == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => c.onNavTap(e.key),
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(e.value.icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(e.value.label,
                        style: TextStyle(
                          fontSize: 11.5, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: Colors.white, fontFamily: 'Poppins',
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SimpleStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _StockSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;

  const _StockSummaryRow({required this.label, required this.value, this.valueColor, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor ?? colors.textPrimary, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  const _QA({required this.icon, required this.label});
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
