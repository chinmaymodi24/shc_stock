import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import '../../../routes/app_routes.dart';

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
      icon: Icons.inventory_2_outlined,
      label: 'Products',
      route: AppRoutes.products,
    ),
    _NavItem(
      icon: Icons.category_outlined,
      label: 'Categories',
      route: AppRoutes.categories,
    ),
    _NavItem(
      icon: Icons.warehouse_outlined,
      label: 'Stock',
      route: AppRoutes.stock,
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
      icon: Icons.people_outline_rounded,
      label: 'Clients',
      route: AppRoutes.clients,
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Reports',
      route: AppRoutes.reports,
    ),
    _NavItem(
      icon: Icons.manage_accounts_outlined,
      label: 'Users',
      route: AppRoutes.users,
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
    AppRoutes.purchase,
    AppRoutes.sales,
  };

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    final tc = Get.find<ThemeController>();

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
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Image.asset(
                'assets/logo.png',
                height: 90,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 8),

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

          // ── Theme Selector ───────────────────────────────────────
          const SidebarThemeSelector(),

          // ── Admin Profile ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'admin@shc.com',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Get.dialog(const _SignOutDialog()),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Selector
// ─────────────────────────────────────────────────────────────────────────────
class SidebarThemeSelector extends StatelessWidget {
  const SidebarThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tc = Get.find<ThemeController>();
      final colors = context.appColors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'THEME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                children: [
                  _ThemeBtn(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Light',
                    isActive: tc.isLight,
                    onTap: () => tc.setTheme(ThemeMode.light),
                  ),
                  Container(width: 1, color: colors.divider),
                  _ThemeBtn(
                    icon: Icons.nightlight_round,
                    label: 'Dark',
                    isActive: tc.isDark,
                    onTap: () => tc.setTheme(ThemeMode.dark),
                  ),
                  Container(width: 1, color: colors.divider),
                  _ThemeBtn(
                    icon: Icons.devices_rounded,
                    label: 'System',
                    isActive: tc.isSystem,
                    onTap: () => tc.setTheme(ThemeMode.system),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ThemeBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryOrange.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.primaryOrange
                    : colors.textPrimary.withValues(alpha: 0.8),
              ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sign Out Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 320),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.primaryOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: Get.back,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.comingSoonBadge,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Divider(height: 1, color: colors.divider),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryOrange.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will be returned to the login screen. Any unsaved changes will be lost.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            Get.offAllNamed(AppRoutes.login);
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            'Yes, Sign Out',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
