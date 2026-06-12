import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_text_styles.dart';
import 'package:shc_stock/app/modules/auth/widgets/login_form.dart';

class WebLoginLayout extends StatelessWidget {
  const WebLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // backgroundColor: colors.background,
      backgroundColor: context.isDarkMode
          ? Color(0xFF000c25)
          : AppColors.backgroundLavender,
      body: Column(
        children: [
          // ─── Main Row: Left Panel + Right Card ───
          Expanded(
            child: Padding(
              // Overall outer spacing — scales with screen size
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05, // 5% each side
                vertical: size.height * 0.03, // 3% top & bottom
              ),
              child: Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT PANEL — exactly 50% of content area
                    Expanded(flex: 10, child: _buildLeftPanel(context, size)),

                    // RIGHT PANEL — exactly 50% of content area
                    Expanded(flex: 6, child: _buildRightPanel(context, size)),
                  ],
                ),
              ),
            ),
          ),

          // ─── Footer ───
          _buildFooter(context, size),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  LEFT PANEL
  //  Stack:
  //    Layer 1 (bottom): Warehouse image anchored to panel bottom (~62% height)
  //    Layer 2 (top)   : Logo + Hero text sitting above the image
  // ───────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(BuildContext context, Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Layer 1: Background warehouse image (bottom ~62%) ──
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          height: size.height * 0.67,
          child: Image.asset(
            context.isDarkMode
                ? 'assets/background_dark.png'
                : 'assets/background_light.png',
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
          ),
        ),

        // ── Layer 2: Logo + Hero text on top ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic top breathing room
            SizedBox(height: size.height * 0.04),

            // Logo — width proportional to screen width
            Padding(
              // Left padding relative to the panel (panel = 45% of screen after outer pad)
              padding: EdgeInsets.only(left: size.width * 0.019),
              child: Image.asset(
                'assets/logo.png',
                // Panel is ~45% of screen → logo takes ~30% of panel width
                width: size.width * 0.15,
                fit: BoxFit.fitWidth,
              ),
            ),

            SizedBox(height: size.height * 0.025),

            // Hero headline + accent + subtitle
            _buildHeroText(context, size),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroText(BuildContext context, Size size) {
    // Font sizes scale with screen width for all resolutions
    // Each panel is now 50% of (screen - 10% outer pad) ≈ 45% of screen
    final double headingFontSize = size.width * 0.017;
    final double bodyFontSize = size.width * 0.007;

    return Padding(
      padding: EdgeInsets.only(
        left: size.width * 0.035,
        right: size.width * 0.015,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero headline
          RichText(
            text: TextSpan(
              style: AppTextStyles.heroHeading.copyWith(
                fontSize: headingFontSize,
              ),
              children: [
                TextSpan(
                  text: 'Built for ',
                  style: context.isDarkMode
                      ? TextStyle(color: Colors.white)
                      : null,
                ),
                TextSpan(
                  text: 'efficiency.',
                  style: AppTextStyles.heroHeading.copyWith(
                    fontSize: headingFontSize,
                    color: AppColors.primaryPurple,
                  ),
                ),
                TextSpan(text: '\nDesigned for ',
                  style: context.isDarkMode
                      ? TextStyle(color: Colors.white)
                      : null,
                ),
                TextSpan(
                  text: 'growth.',
                  style: AppTextStyles.heroHeading.copyWith(
                    fontSize: headingFontSize,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: size.height * 0.014),

          // Orange accent underline
          Container(
            width: size.width * 0.022,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          SizedBox(height: size.height * 0.014),

          // Subtitle body text
          Text(
            'Powerful tools to manage stock,\npurchases, sales and reports –\nall in one place.',
            style: AppTextStyles.heroBody.copyWith(
              fontSize: bodyFontSize,
              color: const Color(0xFF5d6093),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  RIGHT PANEL (Login Card)
  // ───────────────────────────────────────────────────────────────
  Widget _buildRightPanel(BuildContext context, Size size) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: size.width * 0.025, // slight breathing room on right
        top: size.height * 0.10, // card top aligns ~with logo bottom
        bottom: size.height * 0.06,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(size.width * 0.012),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 48,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.028, // inner card horizontal padding
            vertical: size.height * 0.038, // inner card vertical padding
          ),
          child: const LoginForm(showLogo: false, isMobile: false),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  //  FOOTER
  // ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
      child: Text(
        '© 2024 Secure Heat Care. All rights reserved.',
        style: AppTextStyles.copyrightCtx(context),
      ),
    );
  }
}
