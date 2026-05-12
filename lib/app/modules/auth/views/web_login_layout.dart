import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_text_styles.dart';
import 'package:shc_stock/app/modules/auth/widgets/language_selector.dart';
import 'package:shc_stock/app/modules/auth/widgets/login_form.dart';
import 'package:shc_stock/app/modules/auth/widgets/shc_logo.dart';

class WebLoginLayout extends StatelessWidget {
  const WebLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: Stack(
        children: [
          // Full page content
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.fitWidth,
              ),
            ),
            child: Column(
              children: [
                // Top bar with logo and language
                _buildTopBar(),

                // Main content
                Expanded(
                  child: Row(
                    children: [
                      // Left: Hero section
                      Expanded(
                        flex: 55,
                        child: _buildHeroSection(screenWidth, screenHeight),
                      ),

                      // Right: Login card
                      Expanded(
                        flex: 45,
                        child: _buildLoginCard(screenHeight, context),
                      ),
                    ],
                  ),
                ),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SHCLogo(),
          const LanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
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
          const SizedBox(height: 16),

          // Orange underline accent
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            'Powerful tools to manage stock,\npurchases, sales and reports –\nall in one place.',
            style: AppTextStyles.heroBody,
          ),
          const SizedBox(height: 32),

          // Warehouse illustration
          /*Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return WarehouseIllustration(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                );
              },
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildLoginCard(double screenHeight,BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 56, left: 24, bottom: 32, top: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.width * 0.23, maxHeight: context.height * 0.7),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
              child: const LoginForm(showLogo: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        '© 2024 Secure Heat Care. All rights reserved.',
        style: AppTextStyles.copyright,
      ),
    );
  }
}
