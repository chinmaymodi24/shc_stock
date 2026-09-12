import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/settings/views/mobile_settings_view.dart';
import 'package:shc_stock/app/modules/settings/views/web_settings_layout.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/views/stock_adjustment_dialog.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';
import 'package:get/get.dart';
import 'support/session.dart';

// Offline stand-ins so pumping StockAdjustmentDialog doesn't fire real Dio
// requests (products/categories/stock all fetch on onInit) — those leave a
// dangling connect-timeout Timer the test framework flags as a leak, since
// nothing in a widget test is actually listening on the API host.
class _OfflineProductsController extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {}
}

class _OfflineCategoriesController extends CategoriesController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchCategories() async {}
}

/// Settings for the signed-in test user without the load, which would try the
/// (disabled) network and raise an error toast mid-test.
class _OfflineSettingsController extends SettingsController {
  @override
  Future<void> fetchSettings() async {}
}

class _OfflineStockController extends StockController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchItems() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// The "secondary pill next to a primary AppAsyncButton" pattern appears on
// several dialogs — a hand-rolled Container/InkWell for Cancel/Reset next to
// a real ElevatedButton for Save/Apply/Update. Matching their padding by eye
// is fragile: Material's own button metrics and a plain Container's don't
// always agree down to the pixel, which is exactly what shipped as a visibly
// taller Save button on the Add/Edit Subcategory dialog.
//
// Every dialog in that family now stretches both buttons to the row's own
// tallest content (IntrinsicHeight + CrossAxisAlignment.stretch) instead of
// trusting padding to land on the same height. These tests pin that down by
// asserting the two buttons in each fixed row render at the exact same
// height — a change that quietly drops the IntrinsicHeight wrapper would fail
// this immediately even where a test font hides the original pixel gap.
// ─────────────────────────────────────────────────────────────────────────────

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [AppThemeColors.light]),
  home: child,
);

/// Full-page pump for widgets that render the shared web chrome
/// (WebSidebar/WebTopBar), which reach for ThemeController/
/// ThemeRippleController at build time — matches the pattern established in
/// stats_cards_render_test.dart.
Future<void> _pumpWebPage(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

/// Finds the rendered rect of the widget's own subtree by its widget type,
/// under a [Row] that should contain exactly one of each.
Rect _rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  // Cards and actions only render for someone allowed to see them.
  setUp(signInSuperAdmin);
  tearDown(Get.reset);

  group('StatusUpdateDialogShell (Purchase/Sale "Update Status")', () {
    testWidgets('Cancel and Update render at the same height', (tester) async {
      await tester.pumpWidget(
        _host(
          StatusUpdateDialogShell(
            title: 'Update Status',
            subtitle: 'Choose a new status',
            body: const SizedBox(height: 40),
            onSave: () async {},
          ),
        ),
      );

      final cancel = _rectOf(
        tester,
        find.ancestor(of: find.text('Cancel'), matching: find.byType(InkWell)),
      );
      final update = _rectOf(tester, find.byType(AppAsyncButton));
      expect(cancel.height, update.height);
    });
  });

  group('StockAdjustmentDialog footer', () {
    testWidgets('Cancel and Save render at the same height', (tester) async {
      Get.put<CategoriesController>(
        _OfflineCategoriesController(),
        permanent: true,
      );
      Get.put<ProductsController>(_OfflineProductsController());
      Get.put<StockController>(_OfflineStockController());
      await tester.pumpWidget(_host(const StockAdjustmentDialog()));
      await tester.pump();

      final cancel = _rectOf(
        tester,
        find.ancestor(of: find.text('Cancel'), matching: find.byType(InkWell)),
      );
      final save = _rectOf(tester, find.byType(AppAsyncButton));
      expect(cancel.height, save.height);
    });
  });

  group('Settings "Reset / Apply" row', () {
    testWidgets('mobile: Reset and Apply render at the same height', (
      tester,
    ) async {
      Get.put<SettingsController>(
        _OfflineSettingsController(),
        permanent: true,
      );
      Get.put(ThemeController(), permanent: true);
      Get.put(ThemeRippleController(), permanent: true);
      await tester.pumpWidget(_host(const MobileSettingsView()));
      await tester.pump();

      final reset = _rectOf(
        tester,
        find.ancestor(of: find.text('Reset'), matching: find.byType(InkWell)),
      );
      final apply = _rectOf(tester, find.byType(AppAsyncButton));
      expect(reset.height, apply.height);
    });

    testWidgets('web: Reset and Apply render at the same height', (
      tester,
    ) async {
      final settings = Get.put<SettingsController>(
        _OfflineSettingsController(),
        permanent: true,
      );
      settings.tab.value = 3; // Preferences — where Reset/Apply live

      await _pumpWebPage(tester, const WebSettingsLayout());

      final reset = _rectOf(
        tester,
        find.ancestor(of: find.text('Reset'), matching: find.byType(InkWell)),
      );
      final apply = _rectOf(tester, find.byType(AppAsyncButton));
      expect(reset.height, apply.height);
    });
  });
}
