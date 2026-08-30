import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_switch_helper.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings — left tab nav (Profile / Notifications / Security / Preferences)
// + right content panel. State lives in SettingsController (registered by
// SettingsBinding) — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class WebSettingsLayout extends GetView<SettingsController> {
  const WebSettingsLayout({super.key});

  static const _tabs = ['Profile', 'Notifications', 'Security', 'Preferences'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WebTopBar(),

                // ── Page title ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage your account, notifications, and preferences',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body: tab nav + content ───────────────────────────────
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left tab nav
                      Container(
                        width: 200,
                        height: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: colors.divider),
                          ),
                        ),
                        child: Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < _tabs.length; i++)
                                _NavTab(
                                  label: _tabs[i],
                                  selected: controller.tab.value == i,
                                  colors: colors,
                                  onTap: () => controller.tab.value = i,
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Right content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                          child: Obx(() => _buildContent(context, colors)),
                        ),
                      ),
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

  Widget _buildContent(BuildContext context, AppThemeColors colors) {
    switch (controller.tab.value) {
      case 1:
        return _notificationsTab(colors);
      case 2:
        return _securityTab(colors);
      case 3:
        return _preferencesTab(context, colors);
      default:
        return _profileTab(colors);
    }
  }

  // ── Profile ─────────────────────────────────────────────────────
  Widget _profileTab(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Profile', colors),
        const SizedBox(height: 20),
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
                  _sessionUser?.initials ?? '—',
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
        _field(label: 'Full Name', ctrl: controller.nameCtrl, colors: colors),
        const SizedBox(height: 16),
        _field(label: 'Email', ctrl: controller.emailCtrl, colors: colors),
        const SizedBox(height: 16),
        _field(
          label: 'Role',
          ctrl: null,
          hint: _sessionUser?.role ?? '—',
          enabled: false,
          colors: colors,
        ),
        const SizedBox(height: 24),
        _orangeButton(label: 'Save Changes', onTap: controller.saveSettings),
      ],
    );
  }

  // ── Notifications ───────────────────────────────────────────────
  Widget _notificationsTab(AppThemeColors colors) {
    final rows = [
      (
        'Low stock alerts',
        'Get notified when items fall below reorder point',
        controller.lowStock.value,
        (bool v) => controller.toggle(controller.lowStock, v),
      ),
      (
        'Delivery updates',
        'Incoming and outgoing shipment status changes',
        controller.delivery.value,
        (bool v) => controller.toggle(controller.delivery, v),
      ),
      (
        'Payment reminders',
        'Client dues and supplier payments coming due',
        controller.payment.value,
        (bool v) => controller.toggle(controller.payment, v),
      ),
      (
        'Weekly summary email',
        'A digest of activity every Monday morning',
        controller.weekly.value,
        (bool v) => controller.toggle(controller.weekly, v),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Notifications', colors),
        const SizedBox(height: 8),
        for (int i = 0; i < rows.length; i++) ...[
          _toggleRow(
            title: rows[i].$1,
            subtitle: rows[i].$2,
            value: rows[i].$3,
            onChanged: rows[i].$4,
            colors: colors,
          ),
          if (i != rows.length - 1) Divider(height: 1, color: colors.divider),
        ],
      ],
    );
  }

  // ── Security ────────────────────────────────────────────────────
  Widget _securityTab(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Security', colors),
        const SizedBox(height: 20),
        _field(
          label: 'Current Password',
          ctrl: controller.curPwdCtrl,
          obscure: true,
          colors: colors,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'New Password',
          ctrl: controller.newPwdCtrl,
          hint: 'Enter new password',
          obscure: true,
          colors: colors,
        ),
        const SizedBox(height: 16),
        _field(
          label: 'Confirm New Password',
          ctrl: controller.confirmPwdCtrl,
          hint: 'Re-enter new password',
          obscure: true,
          colors: colors,
        ),
        const SizedBox(height: 24),
        _purpleButton(
          label: 'Update Password',
          onTap: controller.changePassword,
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 20),
        _toggleRow(
          title: 'Two-factor authentication',
          subtitle: 'Add an extra layer of security to your account',
          value: controller.twoFactor.value,
          onChanged: (v) => controller.toggle(controller.twoFactor, v),
          colors: colors,
          padded: false,
        ),
      ],
    );
  }

  // ── Preferences ─────────────────────────────────────────────────
  Widget _preferencesTab(BuildContext context, AppThemeColors colors) {
    final tc = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Preferences', colors),
        const SizedBox(height: 20),
        Text(
          'Theme',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Choose how the dashboard looks',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              _themeChip(
                icon: '☀',
                label: 'Light',
                selected: tc.isLight,
                colors: colors,
                onTap: () => switchThemeWithRipple(context, ThemeMode.light),
              ),
              const SizedBox(width: 12),
              _themeChip(
                icon: '🌙',
                label: 'Dark',
                selected: tc.isDark,
                colors: colors,
                onTap: () => switchThemeWithRipple(context, ThemeMode.dark),
              ),
              const SizedBox(width: 12),
              _themeChip(
                icon: '🖥',
                label: 'System',
                selected: tc.isSystem,
                colors: colors,
                onTap: () => switchThemeWithRipple(context, ThemeMode.system),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Default Rows Per Page',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        _dropdown<int>(
          value: controller.rowsPerPage.value,
          width: 90,
          items: const [5, 10, 20, 50],
          itemLabel: (v) => '$v',
          onChanged: (v) => controller.rowsPerPage.value = v,
          colors: colors,
        ),
        const SizedBox(height: 22),
        Text(
          'Date Format',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        _dropdown<String>(
          value: controller.dateFormat.value,
          width: 230,
          items: const [
            'MMM D, YYYY (Jul 18, 2026)',
            'DD/MM/YYYY (18/07/2026)',
            'YYYY-MM-DD (2026-07-18)',
          ],
          itemLabel: (v) => v,
          onChanged: (v) => controller.dateFormat.value = v,
          colors: colors,
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: colors.divider),
        Obx(
          () => _toggleRow(
            title: 'Auto-generate invoice numbers',
            subtitle:
                'Prefill "Invoice No." on Add Purchase / Add Sale with the next '
                'number in the series',
            value: controller.autoNumberDocs.value,
            onChanged: (v) => controller.autoNumberDocs.value = v,
            colors: colors,
          ),
        ),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 22),
        Text(
          'Low Stock Alert Threshold',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Flag a product as Low Stock when its stock falls to this level or '
          'below. Used only where a product has no minimum of its own. '
          'Off = per-product minimums only.',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => _dropdown<int>(
            value: const [0, 5, 10, 15, 20, 25, 50, 100]
                    .contains(controller.lowStockThreshold.value)
                ? controller.lowStockThreshold.value
                : 0,
            width: 120,
            items: const [0, 5, 10, 15, 20, 25, 50, 100],
            itemLabel: (v) => v == 0 ? 'Off' : '$v units',
            onChanged: (v) => controller.lowStockThreshold.value = v,
            colors: colors,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _greyButton(
              label: 'Reset',
              colors: colors,
              onTap: () {
                controller.rowsPerPage.value = 10;
                controller.dateFormat.value = 'MMM D, YYYY (Jul 18, 2026)';
                controller.autoNumberDocs.value = true;
                controller.lowStockThreshold.value = 0;
              },
            ),
            const SizedBox(width: 12),
            _orangeButton(label: 'Apply', onTap: controller.saveSettings),
          ],
        ),
      ],
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────
  Widget _sectionTitle(String t, AppThemeColors colors) => Text(
    t,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
      fontFamily: 'Poppins',
    ),
  );

  Widget _field({
    required String label,
    TextEditingController? ctrl,
    String? hint,
    bool enabled = true,
    bool obscure = false,
    required AppThemeColors colors,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
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
            obscureText: obscure,
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
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppThemeColors colors,
    bool padded = true,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padded ? 16 : 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip({
    required String icon,
    required String label,
    required bool selected,
    required AppThemeColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryOrange : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primaryOrange : colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
    required double width,
    required AppThemeColors colors,
  }) {
    return Container(
      width: width,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
          dropdownColor: colors.surface,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _orangeButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    return AppAsyncButton(
      label: label,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      radius: 8,
    );
  }

  Widget _purpleButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    return AppAsyncButton(
      label: label,
      onPressed: onTap,
      background: AppColors.primaryPurple,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      radius: 8,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
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

// Left-nav tab item
class _NavTab extends StatelessWidget {
  final String label;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _NavTab({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? colors.purple.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.purple : colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

/// The signed-in user, for the avatar initials and the read-only Role field.
SessionUser? get _sessionUser => Get.isRegistered<SessionController>()
    ? Get.find<SessionController>().user.value
    : null;
