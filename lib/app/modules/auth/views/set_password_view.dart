import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/auth/controllers/set_password_controller.dart';

/// "Choose your own password" — shown once, to an employee whose password was
/// set by somebody else. One layout for web and mobile: a single centred card
/// reads fine at both widths.
class SetPasswordView extends StatelessWidget {
  const SetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = Get.put(SetPasswordController());
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your own password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your account was set up with a password somebody else '
                      'chose. Pick one only you know to continue.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Obx(
                      () => _PasswordBox(
                        label: 'Current password',
                        controller: c.currentCtrl,
                        obscure: !c.showCurrent.value,
                        onToggle: () => c.showCurrent.toggle(),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _PasswordBox(
                        label: 'New password',
                        controller: c.newCtrl,
                        obscure: !c.showNew.value,
                        onToggle: () => c.showNew.toggle(),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _PasswordBox(
                        label: 'Confirm new password',
                        controller: c.confirmCtrl,
                        obscure: !c.showNew.value,
                        onToggle: () => c.showNew.toggle(),
                        colors: colors,
                        onSubmit: c.save,
                      ),
                    ),
                    Obx(
                      () => c.error.value == null
                          ? const SizedBox(height: 16)
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 6,
                              ),
                              child: Text(
                                c.error.value!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: brandFontFamily,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: c.isSaving.value ? null : c.save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                appColors.radius,
                              ),
                            ),
                          ),
                          child: c.isSaving.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save and continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: brandFontFamily,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: c.signOut,
                        child: Text(
                          'Sign out',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final AppThemeColors colors;
  final VoidCallback? onSubmit;

  const _PasswordBox({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.colors,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
          style: TextStyle(
            fontSize: 14,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.primaryOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
