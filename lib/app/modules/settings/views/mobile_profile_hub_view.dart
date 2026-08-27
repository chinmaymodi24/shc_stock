import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/sign_out_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mobile "Profile" hub — the landing screen reached from Settings/My Profile.
// Mirrors the web Settings page's four sections (Profile / Notifications /
// Security / Preferences) as a list of entry points instead of tabs, plus an
// account summary card up top. Tapping a row (or the card's edit button)
// reuses the existing edit pages instead of duplicating their UI here.
// ─────────────────────────────────────────────────────────────────────────────
class MobileProfileHubView extends StatelessWidget {
  const MobileProfileHubView({super.key});

  SessionUser? get _user => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().user.value
      : null;

  void _openSettingsTab(int tab) {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    Get.find<SettingsController>().mobileTab.value = tab;
    Get.toNamed(AppRoutes.settingsDetail);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = _user;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.topBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: colors.textPrimary,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.offAllNamed(AppRoutes.dashboard);
            }
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account summary card ─────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '—',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.trim().isNotEmpty == true
                              ? user!.name
                              : 'Signed out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.accent,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (user?.role.trim().isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user!.role,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.success,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Get.toNamed(AppRoutes.profile),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.iconBgPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Settings list ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _settingsRow(
                    colors: colors,
                    icon: Icons.person_outline_rounded,
                    iconColor: colors.purple,
                    iconBg: colors.iconBgPurple,
                    title: 'Profile',
                    subtitle: 'Name, photo, email, role',
                    onTap: () => Get.toNamed(AppRoutes.profile),
                  ),
                  Divider(height: 1, color: colors.divider, indent: 60),
                  _settingsRow(
                    colors: colors,
                    icon: Icons.notifications_none_rounded,
                    iconColor: AppColors.primaryOrange,
                    iconBg: AppColors.primaryOrange.withValues(alpha: 0.12),
                    title: 'Notifications',
                    subtitle: 'Low stock, deliveries, payments',
                    onTap: () => _openSettingsTab(2),
                  ),
                  Divider(height: 1, color: colors.divider, indent: 60),
                  _settingsRow(
                    colors: colors,
                    icon: Icons.lock_outline_rounded,
                    iconColor: colors.purple,
                    iconBg: colors.iconBgPurple,
                    title: 'Security',
                    subtitle: 'Password, two-factor auth',
                    onTap: () => _openSettingsTab(1),
                  ),
                  Divider(height: 1, color: colors.divider, indent: 60),
                  _settingsRow(
                    colors: colors,
                    icon: Icons.tune_rounded,
                    iconColor: colors.success,
                    iconBg: colors.success.withValues(alpha: 0.12),
                    title: 'Preferences',
                    subtitle: 'Theme, rows per page, date format',
                    onTap: () => _openSettingsTab(0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Sign out ───────────────────────────────────────
            Material(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Get.dialog(const SignOutConfirmDialog()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: colors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.error,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow({
    required AppThemeColors colors,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accent,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
