import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/app_toast.dart';

/// Shared drawer used by all mobile layouts.
/// Pass the current [activeRoute] so the correct item is highlighted.
class AppDrawer extends StatelessWidget {
  final String activeRoute;
  const AppDrawer({super.key, required this.activeRoute});

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
      icon: Icons.settings_outlined,
      label: 'Settings',
      route: AppRoutes.settings,
    ),
  ];

  static const _enabled = {
    AppRoutes.dashboard,
    AppRoutes.products,
    AppRoutes.categories,
    AppRoutes.purchase,
    AppRoutes.sales,
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
                  Image.asset(
                    'assets/logo.png',
                    width: 100,
                    fit: BoxFit.fitWidth,
                  ),
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x33F47B20),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Text(
                    'admin@secureheatcare.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0AECF),
                      fontFamily: 'Poppins',
                    ),
                  ),
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

            // ── Theme Selector ────────────────────────────────
            const _DrawerThemeSelector(),

            // ── Footer ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.primaryOrange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer Theme Selector ─────────────────────────────────────────────────────
class _DrawerThemeSelector extends StatelessWidget {
  const _DrawerThemeSelector();

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: colors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              // Compact 3-icon toggle
              Obx(
                () => Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.iconBgPurple,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DrawerThemeBtn(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Light',
                        isActive: tc.isLight,
                        onTap: () => tc.setTheme(ThemeMode.light),
                      ),
                      _DrawerThemeBtn(
                        icon: Icons.nightlight_round,
                        label: 'Dark',
                        isActive: tc.isDark,
                        onTap: () => tc.setTheme(ThemeMode.dark),
                      ),
                      _DrawerThemeBtn(
                        icon: Icons.devices_rounded,
                        label: 'System',
                        isActive: tc.isSystem,
                        onTap: () => tc.setTheme(ThemeMode.system),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
      ],
    );
  }
}

class _DrawerThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerThemeBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      textStyle: const TextStyle(
        fontSize: 11,
        fontFamily: 'Poppins',
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1240),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : context.appColors.textSecondary,
          ),
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
