import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded,        label: 'Dashboard',   route: AppRoutes.dashboard),
    _NavItem(icon: Icons.inventory_2_outlined,     label: 'Products',    route: AppRoutes.products),
    _NavItem(icon: Icons.category_outlined,        label: 'Categories',  route: AppRoutes.categories),
    _NavItem(icon: Icons.warehouse_outlined,       label: 'Stock',       route: AppRoutes.stock),
    _NavItem(icon: Icons.shopping_bag_outlined,    label: 'Purchase',    route: AppRoutes.purchase),
    _NavItem(icon: Icons.point_of_sale_outlined,   label: 'Sales',       route: AppRoutes.sales),
    _NavItem(icon: Icons.people_outline_rounded,   label: 'Clients',     route: AppRoutes.clients),
    _NavItem(icon: Icons.bar_chart_rounded,        label: 'Reports',     route: AppRoutes.reports),
    _NavItem(icon: Icons.manage_accounts_outlined, label: 'Users',       route: AppRoutes.users),
    _NavItem(icon: Icons.settings_outlined,        label: 'Settings',    route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    return Container(
      width: 200,
      color: AppColors.primaryOrange,
      child: Column(
        children: [
          // ── Logo ──
          GestureDetector(
            onTap: () => Get.offNamed(AppRoutes.dashboard),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Image.asset('assets/logo.png', width: 80, height: 40),
            ),
          ),
          const SizedBox(height: 8),

          // ── Nav Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = currentRoute.startsWith(item.route);
                return _SidebarNavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () {
                    if (item.route == AppRoutes.dashboard ||
                        item.route == AppRoutes.products ||
                        item.route == AppRoutes.categories) {
                      Get.offNamed(item.route);
                    } else {
                      Get.snackbar(
                        '🚧 Coming Soon',
                        '${item.label} module is under development.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primaryPurple,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // ── Admin profile ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.08),
            ),
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
                GestureDetector(
                  onTap: () => Get.offNamed(AppRoutes.login),
                  child: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
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
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primaryOrange : Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
