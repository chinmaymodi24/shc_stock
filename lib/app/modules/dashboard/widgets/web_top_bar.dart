import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared web top bar — used across all module pages so the header stays common.
// Layout:  [ 🔍 Search anything... ] ............ [ 🔔 ] [ theme toggle ] [ CM ]
// ─────────────────────────────────────────────────────────────────────────────
class WebTopBar extends StatelessWidget {
  /// Initials shown in the avatar (defaults to the current user's).
  final String initials;
  const WebTopBar({super.key, this.initials = 'CM'});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          const _TopSearchBox(),
          const Spacer(),
          _HeaderBellBtn(colors: colors),
          const SizedBox(width: 12),
          const _HeaderThemeToggle(),
          const SizedBox(width: 12),
          _HeaderAvatar(initials: initials),
        ],
      ),
    );
  }
}

// Global "Search anything..." stub — grey filled, borderless.
class _TopSearchBox extends StatelessWidget {
  const _TopSearchBox();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return Container(
      width: 440,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.textHint, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search anything...',
              style: TextStyle(
                fontSize: 13,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Notification bell — light grey rounded-square button with an orange dot.
class _HeaderBellBtn extends StatelessWidget {
  final AppThemeColors colors;
  const _HeaderBellBtn({required this.colors});

  @override
  Widget build(BuildContext context) {
    final bg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return InkWell(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: colors.textSecondary,
              size: 21,
            ),
          ),
          Positioned(
            top: 9,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: bg, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact light/dark theme toggle pill (sun ↔ moon knob).
class _HeaderThemeToggle extends StatelessWidget {
  const _HeaderThemeToggle();

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    final colors = context.appColors;
    return Obx(() {
      final isDark = tc.isDark;
      final track = colors.background.computeLuminance() > 0.5
          ? const Color(0xFFF1F2F4)
          : colors.inputFill;
      return InkWell(
        onTap: () => tc.setTheme(isDark ? ThemeMode.light : ThemeMode.dark),
        child: Container(
          width: 62,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 14,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Current-user avatar — filled navy circle with initials.
class _HeaderAvatar extends StatelessWidget {
  final String initials;
  const _HeaderAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.primaryPurple,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
