import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_text_styles.dart';
import 'package:shc_stock/app/modules/auth/controllers/login_controller.dart';
import 'shc_logo.dart';

// ═════════════════════════════════════════════════════════════════════════════
// OLD LOGIN FORM UI — replaced 2026-07-11 with a simplified design.
// Kept here (commented out) for reference / easy rollback.
// ═════════════════════════════════════════════════════════════════════════════
/*
class LoginForm extends GetView<LoginController> {
  final bool isMobile;
  final bool showLogo;

  const LoginForm({
    super.key,
    this.showLogo = true,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile: show full logo at top
          if (showLogo) ...[
            const Center(child: SHCLogo()),
            const SizedBox(height: 24),
          ],

          // Web only: theme toggle at top-right of card
          if (!showLogo) ...[
            Align(
              alignment: Alignment.centerRight,
              child: const _LoginThemeToggle(),
            ),
            const SizedBox(height: 40),
          ],

          /// TITLE
          Center(
            child: Text(
              'Welcome Back!',
              style: AppTextStyles.heading1Ctx(context),
            ),
          ),

          const SizedBox(height: 8),

          /// SUBTITLE
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.subtitleCtx(context),
                children: [
                  const TextSpan(text: 'Sign in to continue to '),
                  TextSpan(
                    text: 'Secure Heat Care',
                    style: AppTextStyles.subtitleHighlight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildDividerWithDot(),

          isMobile == true
              ? const SizedBox(height: 28)
              : const SizedBox(height: 68),

          /// EMAIL LABEL
          Text('Email Address', style: AppTextStyles.labelCtx(context)),

          const SizedBox(height: 10),

          _buildEmailField(context),

          isMobile == true
              ? const SizedBox(height: 20)
              : const SizedBox(height: 30),

          /// PASSWORD LABEL
          Text('Password', style: AppTextStyles.labelCtx(context)),

          const SizedBox(height: 10),

          _buildPasswordField(context),

          const SizedBox(height: 18),

          /// REMEMBER ME + FORGOT PASSWORD
          _buildRememberMeRow(context),

          isMobile == true
              ? const SizedBox(height: 24)
              : const SizedBox(height: 64),

          /// SIGN IN BUTTON
          _buildSignInButton(),

          const SizedBox(height: 32),

          /// SECURITY BADGE
          _buildSecurityBadge(context),
        ],
      ),
    );
  }

  Widget _buildDividerWithDot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 60, height: 2, color: AppColors.dividerPurple),
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: AppColors.primaryOrange,
            shape: BoxShape.circle,
          ),
        ),
        Container(width: 60, height: 2, color: AppColors.dividerPurple),
      ],
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final colors = context.appColors;
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      validator: controller.validateEmail,
      style: AppTextStyles.inputTextCtx(context),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: AppTextStyles.inputHintCtx(context),
        prefixIcon: const Icon(
          Icons.mail_outline_rounded,
          color: AppColors.inputIcon,
          size: 20,
        ),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final colors = context.appColors;
    return Obx(
      () => TextFormField(
        controller: controller.passwordController,
        obscureText: !controller.isPasswordVisible.value,
        validator: controller.validatePassword,
        style: AppTextStyles.inputTextCtx(context),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => controller.signIn(),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: AppTextStyles.inputHintCtx(context),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.inputIcon,
            size: 20,
          ),
          suffixIcon: InkWell(
            onTap: controller.togglePasswordVisibility,
            child: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: colors.textHint,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeRow(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(
          () => Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: controller.toggleRememberMe,
                  activeColor: AppColors.primaryOrange,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(
                    color: colors.textSecondary,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Remember me', style: AppTextStyles.rememberMeCtx(context)),
            ],
          ),
        ),
        InkWell(
          onTap: controller.forgotPassword,
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            disabledBackgroundColor: AppColors.primaryOrange.withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Sign In', style: AppTextStyles.buttonText),
                  ],
                ),
        ),
      ),
    );
  }


  Widget _buildSecurityBadge(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.comingSoonBadge,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.iconBgPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded prevents the long subtitle text from overflowing.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure. Reliable. Always.',
                  style: AppTextStyles.badgeTitleCtx(context),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your data is safe with us, always and everywhere.',
                  style: AppTextStyles.badgeSubtitleCtx(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact theme toggle for the login card ───────────────────────────────────
class _LoginThemeToggle extends StatelessWidget {
  const _LoginThemeToggle();

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final colors = context.appColors;
    return Obx(() => Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.iconBgPurple,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TBtn(icon: Icons.wb_sunny_rounded,  label: 'Light',  isActive: tc.isLight,  onTap: () => switchThemeWithRipple(context, ThemeMode.light)),
          _TBtn(icon: Icons.devices_rounded,    label: 'System', isActive: tc.isSystem, onTap: () => switchThemeWithRipple(context, ThemeMode.system)),
        ],
      ),
    ));
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TBtn({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: label,
      preferBelow: true,
      textStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.white),
      decoration: BoxDecoration(color: const Color(0xFF1A1240), borderRadius: BorderRadius.circular(6)),
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
          child: Icon(icon, size: 16, color: isActive ? Colors.white : colors.textSecondary),
        ),
      ),
    );
  }
}
*/

// ═════════════════════════════════════════════════════════════════════════════
// NEW LOGIN FORM UI — simplified, minimal style.
// ═════════════════════════════════════════════════════════════════════════════
class LoginForm extends GetView<LoginController> {
  final bool isMobile;
  final bool showLogo;

  const LoginForm({super.key, this.showLogo = true, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            const SHCLogo(width: 190),
            const SizedBox(height: 24),
          ],

          /// TITLE
          Text('Welcome back', style: AppTextStyles.heading1Ctx(context)),

          const SizedBox(height: 4),

          /// SUBTITLE
          Text(
            'Sign in to manage your inventory',
            style: AppTextStyles.subtitleCtx(context),
          ),

          SizedBox(height: isMobile ? 24 : 28),

          /// EMAIL LABEL
          Text('Email or username', style: AppTextStyles.labelCtx(context)),

          const SizedBox(height: 8),

          _buildEmailField(context),

          const SizedBox(height: 18),

          /// PASSWORD LABEL
          Text('Password', style: AppTextStyles.labelCtx(context)),

          const SizedBox(height: 8),

          _buildPasswordField(context),

          const SizedBox(height: 16),

          /// REMEMBER ME + FORGOT PASSWORD
          _buildRememberMeRow(context),

          SizedBox(height: isMobile ? 24 : 28),

          /// SIGN IN BUTTON
          _buildSignInButton(),

          const SizedBox(height: 16),

          /// SUPPORT LINE
          Center(
            child: Text(
              'Support: chinmaymodi24@gmail.com',
              style: AppTextStyles.rememberMeCtx(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final colors = context.appColors;
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      validator: controller.validateEmail,
      style: AppTextStyles.inputTextCtx(context),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'you@secureheatcare.com',
        hintStyle: AppTextStyles.inputHintCtx(context),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.accentPurple,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final colors = context.appColors;
    return Obx(
      () => TextFormField(
        controller: controller.passwordController,
        obscureText: !controller.isPasswordVisible.value,
        validator: controller.validatePassword,
        style: AppTextStyles.inputTextCtx(context),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => controller.signIn(),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: AppTextStyles.inputHintCtx(context),
          suffixIcon: InkWell(
            onTap: controller.togglePasswordVisibility,
            child: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: colors.textHint,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.accentPurple,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeRow(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(
          () => Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: controller.toggleRememberMe,
                  activeColor: AppColors.primaryOrange,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: colors.textSecondary, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text('Remember me', style: AppTextStyles.rememberMeCtx(context)),
            ],
          ),
        ),
        InkWell(
          onTap: controller.forgotPassword,
          borderRadius: BorderRadius.circular(4),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Text(
            'Forgot password?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.purple,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            disabledBackgroundColor: AppColors.primaryOrange.withValues(
              alpha: 0.6,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text('Sign in', style: AppTextStyles.buttonText),
        ),
      ),
    );
  }
}
