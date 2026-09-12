import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Blocks a module route the signed-in employee wasn't granted.
//
// Hiding the nav entry is not the same as denying access: the route is still
// reachable by typing the URL on web, by a deep link, or by any Get.toNamed
// left in code. This closes that door, so the sidebar is a convenience and
// this is the actual rule.
//
// An Admin passes everything; Settings is never gated (it holds your own
// profile and password).
// ─────────────────────────────────────────────────────────────────────────────
class PermissionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null || canOpenRoute(route)) return null;

    // Toast after the frame: redirect() runs mid-navigation, and showing a
    // snackbar inside that build would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAppToast(
        'No access',
        'You do not have permission to open this section.',
        backgroundColor: appColors.error,
        colorText: Colors.white,
      );
    });
    return const RouteSettings(name: AppRoutes.dashboard);
  }
}
