import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_text_styles.dart';
import 'package:shc_stock/app/modules/auth/widgets/login_form.dart';
import 'package:shc_stock/app/modules/auth/widgets/shc_logo.dart';

class WebLoginLayout extends StatelessWidget {
  const WebLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: Column(
        children: [
          // Main body: left panel + right card side by side
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── LEFT PANEL ─────────────────────────────────
                Expanded(
                  flex: 55,
                  child: _buildLeftPanel(context),
                ),

                // ─── RIGHT PANEL (Login Card) ────────────────────
                Expanded(
                  flex: 45,
                  child: _buildRightPanel(context),
                ),
              ],
            ),
          ),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  LEFT PANEL
  // ─────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Logo at the very top-left
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 28),
          child: const SHCLogo(),
        ),

        // 2. Hero text labels
        _buildHeroText(),

        // 3. Warehouse image – FULL image visible (no cropping)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 0, bottom: 12),
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 24, top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero headline
          RichText(
            text: TextSpan(
              style: AppTextStyles.heroHeading,
              children: [
                const TextSpan(text: 'Built for '),
                TextSpan(
                  text: 'efficiency.',
                  style: AppTextStyles.heroHeading.copyWith(
                    color: AppColors.primaryPurple,
                  ),
                ),
                const TextSpan(text: '\nDesigned for '),
                TextSpan(
                  text: 'growth.',
                  style: AppTextStyles.heroHeading.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Orange underline accent
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle body text
          Text(
            'Powerful tools to manage stock,\npurchases, sales and reports –\nall in one place.',
            style: AppTextStyles.heroBody,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  RIGHT PANEL (Login Card)
  // ─────────────────────────────────────────────────────────────
  Widget _buildRightPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,   // minimal gap from the left image panel
          right: 48,
          top: 20,
          bottom: 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            minWidth: 320,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A4A3AFF),
                  blurRadius: 48,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 28, 36, 32),
              child: const LoginForm(showLogo: false),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FOOTER
  // ─────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        '© 2024 Secure Heat Care. All rights reserved.',
        style: AppTextStyles.copyright,
      ),
    );
  }
}
