import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_switch_helper.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Settings detail — one dedicated full page per section. Which section
// shows is picked by SettingsController.mobileTab, set by the Profile hub
// before it navigates here. No tab bar: the header title is the section name.
// State lives in SettingsController (registered by SettingsBinding) — no
// setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class MobileSettingsView extends GetView<SettingsController> {
  const MobileSettingsView({super.key});

  static const _titles = ['Preferences', 'Security', 'Notifications'];

  String get _title {
    final i = controller.mobileTab.value;
    return (i >= 0 && i < _titles.length) ? _titles[i] : 'Settings';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
        title: Obx(
          () => Text(
            _title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingIndicator(label: 'Loading settings...');
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildContent(context, colors),
        );
      }),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeColors colors) {
    switch (controller.mobileTab.value) {
      case 1:
        return _securityTab(colors);
      case 2:
        return _notificationsTab(colors);
      default:
        return _preferencesTab(context, colors);
    }
  }

  // ── Preferences ─────────────────────────────────────────────────
  Widget _preferencesTab(BuildContext context, AppThemeColors colors) {
    final tc = Get.find<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Expanded(
                child: _themeChip(
                  icon: '☀',
                  label: 'Light',
                  selected: tc.isLight,
                  colors: colors,
                  onTap: () => switchThemeWithRipple(context, ThemeMode.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeChip(
                  icon: '🌙',
                  label: 'Dark',
                  selected: tc.isDark,
                  colors: colors,
                  onTap: () => switchThemeWithRipple(context, ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _themeChip(
                  icon: '🖥',
                  label: 'System',
                  selected: tc.isSystem,
                  colors: colors,
                  onTap: () => switchThemeWithRipple(context, ThemeMode.system),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // "Default Rows Per Page" is web-only — mobile list pages scroll
        // continuously with no pager — so it isn't shown here.
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
          width: double.infinity,
          items: const [
            'MMM D, YYYY (Jul 18, 2026)',
            'DD/MM/YYYY (18/07/2026)',
            'YYYY-MM-DD (2026-07-18)',
          ],
          itemLabel: (v) => v,
          onChanged: (v) => controller.dateFormat.value = v,
          colors: colors,
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 20),
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
          'Flag a product as Low Stock at or below this level, where the '
          'product has no minimum of its own. Off = per-product minimums only.',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => _dropdown<int>(
            value:
                const [
                  0,
                  5,
                  10,
                  15,
                  20,
                  25,
                  50,
                  100,
                ].contains(controller.lowStockThreshold.value)
                ? controller.lowStockThreshold.value
                : 0,
            width: double.infinity,
            items: const [0, 5, 10, 15, 20, 25, 50, 100],
            itemLabel: (v) => v == 0 ? 'Off' : '$v units',
            onChanged: (v) => controller.lowStockThreshold.value = v,
            colors: colors,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _greyButton(
                label: 'Reset',
                colors: colors,
                onTap: () {
                  controller.dateFormat.value = 'MMM D, YYYY (Jul 18, 2026)';
                  controller.autoNumberDocs.value = true;
                  controller.lowStockThreshold.value = 0;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppAsyncButton(
                label: 'Apply',
                onPressed: controller.saveSettings,
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 14),
                radius: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Security ────────────────────────────────────────────────────
  Widget _securityTab(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 22),
        AppAsyncButton(
          label: 'Update Password',
          onPressed: controller.changePassword,
          expand: true,
          background: AppColors.primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          radius: 10,
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 18),
        _toggleRow(
          title: 'Two-factor authentication',
          subtitle: 'Add an extra layer of security',
          value: controller.twoFactor.value,
          onChanged: (v) => controller.toggle(controller.twoFactor, v),
          colors: colors,
        ),
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

  // ── Shared bits ─────────────────────────────────────────────────
  Widget _field({
    required String label,
    TextEditingController? ctrl,
    String? hint,
    bool enabled = true,
    bool obscure = false,
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
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppThemeColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.8,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
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
      height: 44,
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

  Widget _greyButton({
    required String label,
    required AppThemeColors colors,
    required VoidCallback onTap,
  }) {
    final bg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
