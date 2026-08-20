import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/theme_controller.dart';
import 'app/core/theme/theme_ripple_controller.dart';
import 'app/core/theme/theme_ripple_overlay.dart';
import 'app/core/session/session_controller.dart';
import 'app/routes/app_pages.dart';

void main() {
  final themeController = Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  // Restored from disk in onInit — the top bar and every audit
  // (`modifiedBy`) field read the signed-in user from here.
  Get.put(SessionController(), permanent: true);
  runApp(SecureHeatCareApp(themeController: themeController));
}

class SecureHeatCareApp extends StatelessWidget {
  final ThemeController themeController;
  const SecureHeatCareApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: 'Secure Heat Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        builder: (context, child) => Overlay(
          // SelectionArea needs an Overlay ancestor (for selection handles /
          // the copy toolbar). `builder` sits above GetMaterialApp's own
          // Navigator, so we give it a dedicated one here.
          initialEntries: [
            OverlayEntry(
              builder: (context) => SelectionArea(
                child: ThemeRippleHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
