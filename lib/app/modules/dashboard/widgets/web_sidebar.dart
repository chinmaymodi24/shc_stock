import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
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

          // ── Theme Selector ──
          const SidebarThemeSelector(),

          // ── Admin profile ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
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
                Tooltip(
                  message: 'Sign Out',
                  preferBelow: false,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1240),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: GestureDetector(
                    onTap: () => Get.dialog(const _SignOutDialog()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 18),
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
}

// ── Theme Selector Widget ─────────────────────────────────────────────────────
class SidebarThemeSelector extends StatelessWidget {
  const SidebarThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(() => Row(
        children: [
          _ThemeBtn(
            icon: Icons.wb_sunny_rounded,
            label: 'Light',
            isActive: tc.isLight,
            onTap: () => tc.setTheme(ThemeMode.light),
          ),
          _ThemeBtn(
            icon: Icons.nightlight_round,
            label: 'Dark',
            isActive: tc.isDark,
            onTap: () => tc.setTheme(ThemeMode.dark),
          ),
          _ThemeBtn(
            icon: Icons.devices_rounded,
            label: 'Auto',
            isActive: tc.isSystem,
            onTap: () => tc.setTheme(ThemeMode.system),
          ),
        ],
      )),
    );
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.primaryOrange : Colors.white70,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppColors.primaryOrange : Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
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

// ── Sign Out Confirm Dialog ───────────────────────────────────────────────────
class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final surface = colors.surface;
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;
    final divider = colors.divider;
    final comingSoonBadge = colors.comingSoonBadge;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 320),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
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
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: AppColors.primaryOrange, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sign Out',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    fontFamily: 'Poppins')),
                            const SizedBox(height: 2),
                            Text('Are you sure you want to sign out?',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: textSecondary,
                                    fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Divider(height: 1, color: divider),
                ),
                // ── Body message ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.primaryOrange.withValues(alpha: 0.8), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will be returned to the login screen. Any unsaved changes will be lost.',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: textSecondary,
                                fontFamily: 'Poppins',
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Actions ──
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
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            Get.offAllNamed(AppRoutes.login);
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white, size: 16),
                          label: const Text('Yes, Sign Out',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
