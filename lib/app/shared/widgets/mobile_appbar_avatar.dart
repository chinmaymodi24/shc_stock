import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

/// The "CM" circle shown at the right end of every mobile page's AppBar.
/// Tapping it opens the Profile hub (account card + Profile / Notifications /
/// Security / Preferences + Sign Out). One shared widget so every page's
/// header carries the exact same control.
class MobileAppBarAvatar extends StatelessWidget {
  /// Trailing gap so it doesn't sit flush against the screen edge.
  final double trailingGap;

  const MobileAppBarAvatar({super.key, this.trailingGap = 12});

  @override
  Widget build(BuildContext context) {
    final initials = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().user.value?.initials ?? '—'
        : '—';
    return Padding(
      padding: EdgeInsets.only(right: trailingGap),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.settings),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
