import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';
import 'language_selector.dart';
import 'shc_logo.dart';

class LoginForm extends GetView<LoginController> {
  final bool showLogo;

  const LoginForm({
    super.key,
    this.showLogo = true,
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

          // Web: language selector at top-right of card
          if (!showLogo) ...[
            Align(
              alignment: Alignment.centerRight,
              child: const LanguageSelector(),
            ),
            const SizedBox(height: 10),
          ],

          /// TITLE
          Center(
            child: Text(
              'Welcome Back!',
              style: AppTextStyles.heading1,
            ),
          ),

          const SizedBox(height: 8),

          /// SUBTITLE
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.subtitle,
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

          const SizedBox(height: 28),

          /// EMAIL LABEL
          Text('Email Address', style: AppTextStyles.label),

          const SizedBox(height: 10),

          _buildEmailField(),

          const SizedBox(height: 20),

          /// PASSWORD LABEL
          Text('Password', style: AppTextStyles.label),

          const SizedBox(height: 10),

          _buildPasswordField(),

          const SizedBox(height: 18),

          /// REMEMBER ME + FORGOT PASSWORD
          _buildRememberMeRow(),

          const SizedBox(height: 24),

          /// SIGN IN BUTTON
          _buildSignInButton(),

          const SizedBox(height: 20),

          /// OR DIVIDER
          _buildOrDivider(),

          const SizedBox(height: 20),

          /// SIGN IN WITH ANOTHER ACCOUNT
          _buildAlternateSignInButton(),

          const SizedBox(height: 24),

          /// SECURITY BADGE
          _buildSecurityBadge(),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      validator: controller.validateEmail,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: AppTextStyles.inputHint,
        prefixIcon: const Icon(
          Icons.mail_outline_rounded,
          color: AppColors.inputIcon,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
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

  Widget _buildPasswordField() {
    return Obx(
      () => TextFormField(
        controller: controller.passwordController,
        obscureText: !controller.isPasswordVisible.value,
        validator: controller.validatePassword,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.inputIcon,
            size: 20,
          ),
          suffixIcon: GestureDetector(
            onTap: controller.togglePasswordVisibility,
            child: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textLight,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
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

  Widget _buildRememberMeRow() {
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
                  activeColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(
                    color: AppColors.inputBorder,
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Remember me', style: AppTextStyles.rememberMe),
            ],
          ),
        ),
        GestureDetector(
          onTap: controller.forgotPassword,
          child: Text('Forgot Password?', style: AppTextStyles.forgotPassword),
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
            disabledBackgroundColor: AppColors.primaryOrange.withOpacity(0.6),
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

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.inputBorder, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR', style: AppTextStyles.orDivider),
        ),
        const Expanded(
          child: Divider(color: AppColors.inputBorder, thickness: 1),
        ),
      ],
    );
  }

  Widget _buildAlternateSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: controller.signInWithAnotherAccount,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Sign in with another account',
              style: AppTextStyles.buttonOutlineText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFECEAFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure. Reliable. Always.',
                  style: AppTextStyles.badgeTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  'Your data is safe with us, always and everywhere.',
                  style: AppTextStyles.badgeSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
