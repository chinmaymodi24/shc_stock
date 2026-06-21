import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
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

                // Theme toggle — respects status-bar safe area
                Positioned(
                  top: topPadding + 12,
                  right: 16,
                  child: const _MobileThemeToggle(),
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

// ── Floating theme toggle for mobile login image overlay ──────────────────────
class _MobileThemeToggle extends StatelessWidget {
  const _MobileThemeToggle();

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Obx(() => Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MobileTBtn(icon: Icons.wb_sunny_rounded,  label: 'Light',  isActive: tc.isLight,  onTap: () => tc.setTheme(ThemeMode.light)),
          _MobileTBtn(icon: Icons.nightlight_round,   label: 'Dark',   isActive: tc.isDark,   onTap: () => tc.setTheme(ThemeMode.dark)),
          _MobileTBtn(icon: Icons.devices_rounded,    label: 'System', isActive: tc.isSystem, onTap: () => tc.setTheme(ThemeMode.system)),
        ],
      ),
    ));
  }
}

class _MobileTBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _MobileTBtn({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white60),
      ),
    );
  }
}
