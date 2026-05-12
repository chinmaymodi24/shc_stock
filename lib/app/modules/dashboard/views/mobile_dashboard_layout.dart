import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/stat_card.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/today_sales_card.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/quick_action_button.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: _buildAppBar(),
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
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
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
            const Text('Stock Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0EFF8)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _StockSummaryRow(label: 'Total Products', value: '1,245', isFirst: true),
                  const Divider(height: 1, color: Color(0xFFF0EFF8)),
                  _StockSummaryRow(label: 'Low Stock Items', value: '23', valueColor: const Color(0xFFEF4444)),
                  const Divider(height: 1, color: Color(0xFFF0EFF8)),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1240), size: 24),
        onPressed: () {},
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
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1240), size: 24), onPressed: () {}),
            Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ],
        ),
      ],
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFF0EFF8))),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0EFF8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF1A1240), fontFamily: 'Poppins')),
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
