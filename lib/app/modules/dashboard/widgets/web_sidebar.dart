import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/shared/widgets/logo_plate.dart';

// ─────────────────────────────────────────────────────────────────────────────
class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    _NavItem(
      icon: Icons.category_outlined,
      label: 'Categories',
      route: AppRoutes.categories,
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      label: 'Products',
      route: AppRoutes.products,
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      label: 'Purchase',
      route: AppRoutes.purchase,
    ),
    _NavItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Sales',
      route: AppRoutes.sales,
    ),
    _NavItem(
      icon: Icons.warehouse_outlined,
      label: 'Inventory',
      route: AppRoutes.stock,
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      label: 'Clients',
      route: AppRoutes.clients,
    ),
    _NavItem(
      icon: Icons.swap_horiz_rounded,
      label: 'Transactions',
      route: AppRoutes.transactions,
    ),
    _NavItem(
      icon: Icons.manage_accounts_outlined,
      label: 'Employee',
      route: AppRoutes.users,
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: AppRoutes.reports,
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
  ];

  static const _enabled = {
    AppRoutes.dashboard,
    AppRoutes.products,
    AppRoutes.categories,
    AppRoutes.stock,
    AppRoutes.transactions,
    AppRoutes.purchase,
    AppRoutes.sales,
    AppRoutes.clients,
    // Reports was left out of this set from an earlier build; the module is
    // fully wired to /api/stats/reports (see ReportsController) so it
    // belongs here same as every other finished module.
    AppRoutes.reports,
    AppRoutes.users,
    AppRoutes.settings,
  };

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;

    final colors = context.appColors;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ────────────────────────────────────────────────
          InkWell(
            onTap: () => Get.offNamed(AppRoutes.dashboard),
            child: Container(
              width: double.infinity,
              // Even breathing room above and below the mark — it used to sit
              // tight against the window chrome and the first nav item.
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
              child: Center(
                child: LogoPlate(isDark: context.isDarkMode, height: 40),
              ),
            ),
          ),

          // ── Nav Items ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = currentRoute.startsWith(item.route);
                final isEnabled = _enabled.contains(item.route);
                return _SidebarNavItem(
                  item: item,
                  isActive: isActive,
                  isEnabled: isEnabled,
                  onTap: () {
                    if (isEnabled) {
                      if (!isActive) Get.offNamed(item.route);
                    } else {
                      showAppToast(
                        '🚧 Coming Soon',
                        '${item.label} module is under development.',
                        backgroundColor: AppColors.primaryPurple,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Item — InkWell with pointer cursor, rounded corners, accurate spacing
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Inactive text/icon: use theme textPrimary (dark navy in light, light lavender in dark)
    final navColor = colors.textPrimary;

    return Padding(
      // Vertical gap between items: 3px
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          // Splash matches active color subtly for non-active items
          splashColor: AppColors.primaryOrange.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryOrange.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            // Increased left padding for icons as requested
            padding: const EdgeInsets.fromLTRB(30, 13, 14, 13),
            decoration: BoxDecoration(
              // Active: solid orange; inactive: transparent
              color: isActive ? AppColors.primaryOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon — 19px, white when active, dark navy when inactive
                Icon(
                  item.icon,
                  size: 19,
                  color: isActive ? Colors.white : navColor,
                ),
                // Gap between icon and label: 10px
                const SizedBox(width: 15),
                // Label
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      // Active: semibold; inactive: medium
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.white : navColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
