import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/views/web_new_sales_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Picking a product from the item autocomplete has to fill the rest of the
// line — HSN, UoM and Rate — and show those values in the boxes. They are
// TextFormFields seeded from `initialValue`, which is read once, so the row
// carries a version that keys them; without it the model was filled but the
// cells kept showing blanks and ₹0.
// ─────────────────────────────────────────────────────────────────────────────

final _product = ProductModel(
  id: '4',
  name: 'CF Bulk (Standard 1260°C)',
  sku: 'CFB-STD-1260',
  categoryId: '1',
  categoryName: 'Ceramic Fiber Products',
  subCategory: 'Bulk',
  unit: 'Kilogram (kg)',
  hsnCode: '68061000',
  sellingPrice: 350,
  costPrice: 250,
  currentStock: 90,
  minimumStock: 10,
  createdAt: DateTime(2026, 1, 1),
);

class _StubProducts extends ProductsController {
  @override
  Future<void> fetchProducts() async {
    products.assignAll([_product]);
    filteredProducts.assignAll([_product]);
  }

  @override
  Future<void> fetchStats() async => stats.value = StatsSnapshot.empty;
}

class _StubCategories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

class _StubClients extends ClientsController {
  @override
  Future<void> fetchClients() async {}
  @override
  Future<void> fetchStats() async {}
}

class _StubSales extends SalesController {
  @override
  Future<void> fetchOrders() async {}
  @override
  Future<void> fetchStats() async {}
}

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = const SessionUser(
    id: 1,
    name: 'Chinmay Modi',
    email: 'shc@gmail.com',
    role: 'Admin',
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('picking a product fills HSN, UoM, rate and the amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put(ThemeController(), permanent: true);
    Get.put(ThemeRippleController(), permanent: true);
    Get.put<SessionController>(_StubSession(), permanent: true);
    Get.put<CategoriesController>(_StubCategories());
    Get.put<ProductsController>(_StubProducts());
    Get.put<ClientsController>(_StubClients());
    Get.put<SalesController>(_StubSales());
    final form = Get.put(AddSaleController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.light]),
        home: const WebNewSalesLayout(),
      ),
    );
    await tester.pump();

    // Type into the item box, then tap the suggestion — exactly the flow the
    // bug report described.
    final itemField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'Type e.g. Ceramic Fiber Blanket 1260...',
    );
    expect(itemField, findsOneWidget);
    await tester.tap(itemField);
    await tester.pump();
    await tester.enterText(itemField, 'bu');
    await tester.pumpAndSettle();

    expect(
      find.text('CF Bulk (Standard 1260°C)'),
      findsWidgets,
      reason: 'the suggestion list should offer the product',
    );
    await tester.tap(find.text('CF Bulk (Standard 1260°C)').last);
    await tester.pumpAndSettle();

    final row = form.items.single;
    expect(row.productId, 4, reason: 'links the line to the product for stock');
    expect(row.hsn, '68061000');
    expect(row.unit, 'Kilogram (kg)');
    expect(row.rate, 350);
    // Quantity defaults to 1 so the line prices itself immediately.
    expect(row.qty, 1);
    expect(row.amount, 350);
    expect(form.taxableValue, 350);

    // …and the boxes on screen show it, not the blanks they were built with.
    expect(find.text('68061000'), findsWidgets);
    expect(find.text('Kilogram (kg)'), findsWidgets);
    expect(find.text('350.00'), findsWidgets);
  });
}
