import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

class WebSidebar extends GetView<DashboardController> {
  const WebSidebar({super.key});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
    _NavItem(icon: Icons.warehouse_outlined, label: 'Stock'),
    _NavItem(icon: Icons.shopping_bag_outlined, label: 'Purchase'),
    _NavItem(icon: Icons.point_of_sale_outlined, label: 'Sales'),
    _NavItem(icon: Icons.people_outline_rounded, label: 'Clients'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
    _NavItem(icon: Icons.manage_accounts_outlined, label: 'Users'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.primaryOrange,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Image.asset(
              "assets/logo.png",
              width: 80,
              height : 40,
            ),
          ),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child:
            // Obx(() =>
                ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isActive = controller.selectedNavIndex.value == index;
                return _SidebarNavItem(
                  item: _navItems[index],
                  isActive: isActive,
                  onTap: () => controller.onNavTap(index),
                );
              },
            ),
            // ),
          ),

          // Admin profile at bottom
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
                      Text('admin@shc.com', style: TextStyle(fontSize: 10.5, color: Colors.white70, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: isActive ? AppColors.primaryOrange : Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(item.label,
                style: TextStyle(
                  fontSize: 13.5, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.primaryOrange : Colors.white,
                  fontFamily: 'Poppins',
                )),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
