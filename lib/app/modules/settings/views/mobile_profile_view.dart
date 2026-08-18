import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Standalone mobile "Profile" page — reached from the dashboard avatar menu.
// ─────────────────────────────────────────────────────────────────────────────
/// Reuses [SettingsController] so this page and the desktop Settings screen
/// load from and save to the same place — /api/settings for the signed-in
/// user. It used to hold a hardcoded name/email and a no-op Save button.
class MobileProfileView extends StatelessWidget {
  const MobileProfileView({super.key});

  SettingsController get _c {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    return Get.find<SettingsController>();
  }

  SessionUser? get _user => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().user.value
      : null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = _c;
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _user?.initials ?? '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _greyButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Change Photo',
                  colors: colors,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            _field(label: 'Full Name', ctrl: c.nameCtrl, colors: colors),
            const SizedBox(height: 16),
            _field(label: 'Email', ctrl: c.emailCtrl, colors: colors),
            const SizedBox(height: 16),
            _field(
              label: 'Role',
              ctrl: null,
              hint: _user?.role ?? '—',
              enabled: false,
              colors: colors,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppAsyncButton(
                label: 'Save Changes',
                onPressed: c.saveSettings,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 15),
                radius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    TextEditingController? ctrl,
    String? hint,
    bool enabled = true,
    required AppThemeColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: ctrl,
          enabled: enabled,
          style: TextStyle(
            fontSize: 13.5,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            filled: true,
            fillColor: enabled ? colors.surface : colors.comingSoonBadge,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _greyButton({
    IconData? icon,
    required String label,
    required AppThemeColors colors,
    required VoidCallback onTap,
  }) {
    final bg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: colors.textSecondary),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
