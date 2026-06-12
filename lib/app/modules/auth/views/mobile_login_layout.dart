import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/language_selector.dart';
import '../widgets/login_form.dart';
import '../widgets/warehouse_illustration.dart';

class MobileLoginLayout extends StatelessWidget {
  const MobileLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top; // status-bar height

    // ── Proportions ──────────────────────────────────────────────
    // Image occupies the top 40% of the screen.
    // White card starts at 36% — overlapping the image by 4%.
    final double imageHeight = size.height * 0.40;
    final double cardTop = size.height * 0.36;

    return Scaffold(
      backgroundColor: colors.background,

      // KEY FIX: StackFit.expand forces the Stack to fill the entire
      // Scaffold body. Without this, the Stack shrinks to the height
      // of its only non-Positioned child (the image SizedBox = 40%),
      // leaving the white card with almost no height to render in.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Warehouse image — Positioned at top (40%) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Stack(
              children: [
                // Image fills its Positioned bounds completely
                Positioned.fill(
                  child: WarehouseIllustration(
                    width: size.width,
                    height: imageHeight,
                  ),
                ),

                // Language selector — respects status-bar safe area
                Positioned(
                  top: topPadding + 12,
                  right: 16,
                  child: const LanguageSelector(),
                ),
              ],
            ),
          ),

          // ── Layer 2: Login card — from 36% to bottom ──────
          Positioned(
            top: cardTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: size.width * 0.06, // ~6% each side
                  right: size.width * 0.06,
                  top: size.height * 0.03, // breathing room below the curve
                  bottom: size.height * 0.04, // safe clearance at bottom
                ),
                child: const LoginForm(showLogo: true, isMobile: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
