import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/products/views/add_product_view.dart';
import 'support/session.dart';

// "Add Product" in the top-bar search opens /products/add. That route used to be
// a separate full-page form whose Save button only showed "saved successfully"
// and never called the API — a product was never created. It now shows the
// Products page with the real Add Product dialog (the one that posts to the
// server) already open.

class _Products extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {}
}

class _Categories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(signInSuperAdmin);
  tearDown(Get.reset);

  testWidgets('/products/add opens the real Add Product dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put(ThemeController(), permanent: true);
    Get.put(ThemeRippleController(), permanent: true);
    // Categories first: ProductsController registers a real one on init if
    // none exists yet, and that one would call the network.
    Get.put<CategoriesController>(_Categories(), permanent: true);
    Get.put<ProductsController>(_Products(), permanent: true);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: const AddProductView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddProductDialog), findsOneWidget);
    // The dialog is the form that validates and saves through the API; the old
    // page's fake success message is nowhere to be found.
    expect(find.text('Item saved successfully!'), findsNothing);
    expect(find.text('Product saved successfully!'), findsNothing);
  });
}
