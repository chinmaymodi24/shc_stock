import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/language_selector.dart';
import '../widgets/login_form.dart';
import '../widgets/warehouse_illustration.dart';

class MobileLoginLayout extends StatelessWidget {
  const MobileLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: Stack(
        children: [
          // Top hero section with warehouse
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.42,
            child: Stack(
              children: [
                // Warehouse illustration
                Positioned.fill(
                  child: WarehouseIllustration(
                    width: screenWidth,
                    height: screenHeight * 0.42,
                  ),
                ),
                // Language selector
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: const LanguageSelector(),
                ),
              ],
            ),
          ),

          // Bottom white card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: screenHeight * 0.36,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A4A3AFF),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: const LoginForm(showLogo: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
