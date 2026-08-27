import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/shared/widgets/logo_plate.dart';

/// Shared drawer used by all mobile layouts.
/// Pass the current [activeRoute] so the correct item is highlighted.
class AppDrawer extends StatelessWidget {
  final String activeRoute;
  const AppDrawer({super.key, required this.activeRoute});

  // Order and icons mirror WebSidebar exactly — every module now has a
  // built, working mobile layout, so the mobile drawer matches the desktop
  // nav item-for-item instead of lagging behind it.
  static const _items = [
    _DrawerItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    _DrawerItem(
      icon: Icons.inventory_2_outlined,
      label: 'Products',
      route: AppRoutes.products,
    ),
    _DrawerItem(
      icon: Icons.category_outlined,
      label: 'Categories',
      route: AppRoutes.categories,
    ),
    _DrawerItem(
      icon: Icons.warehouse_outlined,
      label: 'Inventory',
      route: AppRoutes.stock,
    ),
    _DrawerItem(
      icon: Icons.swap_horiz_rounded,
      label: 'Transactions',
      route: AppRoutes.transactions,
    ),
    _DrawerItem(
      icon: Icons.shopping_bag_outlined,
      label: 'Purchase',
      route: AppRoutes.purchase,
    ),
    _DrawerItem(
      icon: Icons.point_of_sale_outlined,
      label: 'Sales',
      route: AppRoutes.sales,
    ),
    _DrawerItem(
      icon: Icons.people_outline_rounded,
      label: 'Clients',
      route: AppRoutes.clients,
    ),
    _DrawerItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: AppRoutes.reports,
    ),
    _DrawerItem(
      icon: Icons.manage_accounts_outlined,
      label: 'Employee',
      route: AppRoutes.users,
    ),
    _DrawerItem(
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
    AppRoutes.reports,
    AppRoutes.users,
    AppRoutes.settings,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Drawer(
      backgroundColor: colors.drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1240), Color(0xFF2D1F6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LogoPlate(
                    isDark: true,
                    width: 116,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  const SizedBox(height: 16),
                  // Real session data — same SessionController the web top
                  // bar reads, instead of a hardcoded "Admin" placeholder.
                  Obx(() {
                    final user = Get.find<SessionController>().user.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0x33F47B20),
                          child: Text(
                            user?.initials ?? '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryOrange,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user?.name.trim().isNotEmpty == true
                              ? user!.name
                              : 'Signed out',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          user?.role.trim().isNotEmpty == true
                              ? user!.role
                              : (user?.email ?? ''),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0AECF),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // ── Nav Items ────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _items.map((item) {
                  final isActive = item.route == activeRoute;
                  final isEnabled = _enabled.contains(item.route);
                  return _DrawerTile(
                    item: item,
                    isActive: isActive,
                    isEnabled: isEnabled,
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      if (isEnabled && !isActive) {
                        Get.offNamed(item.route);
                      } else if (!isEnabled) {
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
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isActive
            ? AppColors.primaryOrange.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive
                      ? AppColors.primaryOrange
                      : isEnabled
                      ? colors.textSecondary
                      : colors.textHint,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primaryOrange
                          : isEnabled
                          ? colors.textPrimary
                          : colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (!isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.comingSoonBadge,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
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

class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
