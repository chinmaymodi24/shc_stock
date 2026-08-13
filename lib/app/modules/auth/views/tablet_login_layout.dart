import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_switch_helper.dart';
import 'package:shc_stock/app/modules/auth/widgets/login_form.dart';
import 'package:shc_stock/app/modules/auth/widgets/warehouse_illustration.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tablet Login Layout
// Full-screen warehouse illustration + centered frosted-glass login card.
// Used for screens 600 px–1099 px wide (tablets, small laptops in portrait).
// ─────────────────────────────────────────────────────────────────────────────
class TabletLoginLayout extends StatelessWidget {
  const TabletLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundLavender,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-screen warehouse illustration ──────────
          Positioned.fill(
            child: WarehouseIllustration(
              width: size.width,
              height: size.height,
            ),
          ),

          // ── Layer 2: Subtle bottom-fade overlay ─────────────────
          // Keeps the card area readable without hiding the image.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundLavender.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Floating theme toggle (top-right) ───────────
          Positioned(
            top: topPadding + 16,
            right: 24,
            child: const _TabletThemeToggle(),
          ),

          // ── Layer 4: Centered scrollable login card ──────────────
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.05,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 64,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 32,
                      ),
                      // showLogo: true  → SHC logo shown, no in-card toggle
                      // isMobile: false → uses web-size spacers
                      child: const LoginForm(showLogo: true, isMobile: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating theme toggle — Light + System only (no Dark)
// ─────────────────────────────────────────────────────────────────────────────
class _TabletThemeToggle extends StatelessWidget {
  const _TabletThemeToggle();

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Obx(
      () => Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TBtn(
              icon: Icons.wb_sunny_rounded,
              label: 'Light',
              isActive: tc.isLight,
              onTap: () => switchThemeWithRipple(context, ThemeMode.light),
            ),
            _TBtn(
              icon: Icons.devices_rounded,
              label: 'System',
              isActive: tc.isSystem,
              onTap: () => switchThemeWithRipple(context, ThemeMode.system),
            ),
          ],
        ),
      ),
    );
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
