import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/auth/widgets/login_form.dart';

// ═════════════════════════════════════════════════════════════════════════════
// OLD WEB LOGIN LAYOUT — replaced 2026-07-11 with a single unified split card.
// Kept here (commented out) for reference / easy rollback.
// ═════════════════════════════════════════════════════════════════════════════
/*
import 'package:shc_stock/app/core/theme/app_text_styles.dart';

class WebLoginLayout extends StatelessWidget {
  const WebLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
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

  Widget _buildLeftPanel(BuildContext context, Size size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
            frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return AnimatedOpacity(
                  opacity: frame != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  child: child,
                );
              }
              return _LoginImageShimmer(isDark: context.isDarkMode);
            },
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.04),
            Padding(
              padding: EdgeInsets.only(left: size.width * 0.019),
              child: Image.asset(
                'assets/logo.png',
                width: size.width * 0.15,
                fit: BoxFit.fitWidth,
                frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return AnimatedOpacity(
                      opacity: frame != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  }
                  return SizedBox(
                    width: size.width * 0.15,
                    height: size.width * 0.15 * 0.4,
                    child: _LoginImageShimmer(isDark: context.isDarkMode),
                  );
                },
              ),
            ),
            SizedBox(height: size.height * 0.025),
            _buildHeroText(context, size),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroText(BuildContext context, Size size) {
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
                    // Was AppColors.primaryPurple, fixed dark — unlike the
                    // sibling spans above/below it, it never switched to
                    // white in dark mode, so it vanished against the dark
                    // hero panel. Theme-aware purple fixes that.
                    color: context.appColors.purple,
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
          Container(
            width: size.width * 0.022,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          SizedBox(height: size.height * 0.014),
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

  Widget _buildRightPanel(BuildContext context, Size size) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: size.width * 0.025,
        top: size.height * 0.10,
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
            horizontal: size.width * 0.028,
            vertical: size.height * 0.038,
          ),
          child: const LoginForm(showLogo: false, isMobile: false),
        ),
      ),
    );
  }

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

class _LoginImageShimmer extends StatefulWidget {
  final bool isDark;
  const _LoginImageShimmer({this.isDark = false});

  @override
  State<_LoginImageShimmer> createState() => _LoginImageShimmerState();
}

class _LoginImageShimmerState extends State<_LoginImageShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base  = widget.isDark
        ? const Color(0xFF12122A)
        : const Color(0xFFE8E6FF);
    final shine = widget.isDark
        ? const Color(0xFF1E1E3C)
        : const Color(0xFFF2F0FF);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, shine, base],
            stops: [0.0, _anim.value.clamp(0.1, 0.9), 1.0],
          ),
        ),
      ),
    );
  }
}
*/

// ═════════════════════════════════════════════════════════════════════════════
// NEW WEB LOGIN LAYOUT — single unified card, image left / form right.
// ═════════════════════════════════════════════════════════════════════════════
class WebLoginLayout extends StatelessWidget {
  const WebLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.isDarkMode
          ? const Color(0xFF000c25)
          : AppColors.backgroundLavender,
      // No fixed max width/height — the card scales with the viewport,
      // it's sized purely from the % padding below.
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.16,
          vertical: size.height * 0.10,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 48,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: context.appColors.surface,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 11, child: _buildImagePanel(context)),
                  Expanded(flex: 8, child: _buildFormPanel(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePanel(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          context.isDarkMode
              ? 'assets/background_dark.png'
              : 'assets/background_light.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),

        // Purple tint overlay for text legibility
        Container(color: AppColors.primaryPurple.withValues(alpha: 0.38)),

        Padding(
          padding: const EdgeInsets.fromLTRB(40, 36, 32, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Text(
                'Inventory Management',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track stock, shipments, and warehouse activity from one dashboard.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return Container(
      color: context.appColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: const LoginForm(showLogo: true, isMobile: false),
          ),
        ),
      ),
    );
  }
}
