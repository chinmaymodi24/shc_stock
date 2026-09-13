import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/theme/brand_controller.dart';
import 'app/core/theme/theme_controller.dart';
import 'app/core/theme/theme_ripple_controller.dart';
import 'app/core/theme/theme_ripple_overlay.dart';
import 'app/core/session/session_controller.dart';
import 'app/core/export/export_presets.dart';
import 'app/modules/billing/controllers/billing_profile_controller.dart';
import 'app/core/export/export_service.dart';
import 'app/shared/widgets/export/export_overlay_host.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The buyer's brand is read from disk BEFORE the first frame: a blue-branded
  // buyer must never see a flash of the shipped orange on the login screen
  // while the theme loads in.
  final brandController = Get.put(BrandController(), permanent: true);
  await brandController.load();

  final themeController = Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  // Restored from disk in onInit — the top bar and every audit
  // (`modifiedBy`) field read the signed-in user from here.
  Get.put(SessionController(), permanent: true);
  // One export pipeline for the whole app: a job started on Products keeps
  // running (and keeps its toast) after the user navigates elsewhere, and
  // every finished file lands in the same Downloads panel.
  Get.put(ExportService(), permanent: true);
  // Saved column sets, restored from disk — see the dialog's COLUMN PRESET.
  Get.put(ExportPresetStore(), permanent: true);
  // Seller identity, bank details and the invoice defaults. Portal-wide and
  // fetched once per signed-in user — every bill screen reads the same
  // profile. It follows SessionController, so it must be registered after it.
  Get.put(BillingProfileController(), permanent: true);
  runApp(
    SecureHeatCareApp(
      themeController: themeController,
      brandController: brandController,
    ),
  );
}

class SecureHeatCareApp extends StatelessWidget {
  final ThemeController themeController;
  final BrandController brandController;
  const SecureHeatCareApp({
    super.key,
    required this.themeController,
    required this.brandController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read inside the Obx so applying a brand re-themes every screen in
      // place — the spec is explicit that a theme change needs no reload.
      final title = brandController.applied.value.companyName;
      return GetMaterialApp(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        // WidgetOrderTraversalPolicy instead of the default reading-order
        // one: reading order sorts focus nodes by their on-screen rect, and
        // the browser hands focus to the Flutter view before the first layout
        // completes, so that sort read the size of a not-yet-laid-out
        // RenderBox and asserted ("RenderBox was not laid out"). Widget order
        // never touches rects.
        builder: (context, child) => FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          // SelectionArea needs an Overlay ancestor (for selection handles /
          // the copy toolbar). `builder` sits above GetMaterialApp's own
          // Navigator, so we give it a dedicated one here.
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) {
                  final content = ThemeRippleHost(
                    child: ExportOverlayHost(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  // Mobile: text must not be selectable or copyable, so the
                  // app-wide SelectionArea is web/desktop only.
                  return GetPlatform.isMobile
                      ? content
                      : SelectionArea(child: content);
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
