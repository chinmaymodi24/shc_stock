import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'support/session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Product no longer asks for a stock quantity.
//
// Stock belongs to the stock_movements ledger - purchases add, sales remove -
// so typing an opening figure here was a second, contradicting source of
// truth. Taking the field out has one trap: /products rewrites every field it
// is given, so an edit that stops sending currentStock sets it to zero. These
// pin down both halves.
// ─────────────────────────────────────────────────────────────────────────────

/// Records what the dialog asked to be saved, instead of calling the API.
class _CapturingProducts extends ProductsController {
  Map<String, Object?>? added;
  Map<String, Object?>? updated;

  @override
  Future<void> fetchProducts() async {}

  @override
  Future<void> fetchStats() async {}

  @override
  Future<bool> addProduct({
    required String name,
    required String sku,
    required int categoryId,
    int? subCategoryId,
    required String unit,
    required double sellingPrice,
    required double costPrice,
    int currentStock = 0,
    int minimumStock = 0,
    String? brand,
    String? hsnCode,
    String? description,
    double taxPercent = 18.0,
    String? imageUrl,
  }) async {
    added = {
      'name': name,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
    };
    // False on purpose: the dialog then stops without popping itself or
    // firing a toast, so the test can read the payload without a route and
    // an overlay animation to unwind.
    return false;
  }

  @override
  Future<bool> updateProduct({
    required String id,
    required String name,
    required String sku,
    required int categoryId,
    int? subCategoryId,
    required String unit,
    required double sellingPrice,
    required double costPrice,
    int currentStock = 0,
    int minimumStock = 0,
    String? brand,
    String? hsnCode,
    String? description,
    double taxPercent = 18.0,
    String? imageUrl,
  }) async {
    updated = {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
    };
    return false;
  }
}

class _StubCategories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {
    categories.assignAll(const [
      CategoryModel(
        id: '1',
        name: 'Ceramic Fiber Products',
        description: 'Blankets and boards',
        subCategories: [SubCategoryItem(id: 1, name: 'Ceramic Fiber Blanket')],
      ),
    ]);
  }

  @override
  Future<void> fetchStats() async {}
}

final _product = ProductModel(
  id: '7',
  name: 'CF Blanket 1260C',
  sku: 'CFB-1260',
  categoryId: '1',
  categoryName: 'Ceramic Fiber Products',
  subCategory: 'Ceramic Fiber Blanket',
  unit: 'Nos',
  sellingPrice: 1200,
  costPrice: 900,
  currentStock: 437,
  minimumStock: 25,
  createdAt: DateTime(2026, 1, 1),
);

Future<_CapturingProducts> _openDialog(
  WidgetTester tester, {
  ProductModel? product,
  bool duplicate = false,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Categories first: ProductsController.onInit registers a real
  // CategoriesController when none is present, and that one talks to the
  // network.
  final categories = _StubCategories();
  Get.put<CategoriesController>(categories, permanent: true);
  await categories.fetchCategories();

  final products = _CapturingProducts();
  Get.put<ProductsController>(products, permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: Scaffold(
        body: AddProductDialog(product: product, duplicate: duplicate),
      ),
    ),
  );
  await tester.pump();
  return products;
}

/// The button reads Save on a new product and Update on an existing one.
Future<void> _submit(WidgetTester tester, {bool edit = false}) async {
  await tester.tap(find.text(edit ? 'Update' : 'Save'));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(signInSuperAdmin);
  tearDown(Get.reset);

  testWidgets('the Stock Qty field is gone from Add Product', (tester) async {
    await _openDialog(tester);

    expect(find.text('Stock Qty'), findsNothing);
    // The fields around it are untouched.
    expect(find.text('Cost Price (₹)'), findsOneWidget);
    expect(find.text('Selling Price (₹)'), findsOneWidget);
    expect(find.text('HSN Code'), findsOneWidget);
  });

  testWidgets('and from Edit Product', (tester) async {
    await _openDialog(tester, product: _product);

    expect(find.text('Stock Qty'), findsNothing);
    // 437 was the stock; nothing on screen offers it for editing.
    expect(find.text('437'), findsNothing);
  });

  testWidgets('a new product starts at zero stock', (tester) async {
    // Duplicating carries the category, unit and prices across but saves a
    // new product - so this is the add path, pre-filled enough to submit,
    // and it is the case where inheriting a stock figure would be worst.
    final products = await _openDialog(
      tester,
      product: _product,
      duplicate: true,
    );

    await tester.enterText(find.byType(TextField).at(1), 'CFB-1260-COPY');
    await _submit(tester);

    expect(
      products.added,
      isNotNull,
      reason: 'the dialog saved as a new product',
    );
    expect(products.added!['currentStock'], 0);
    expect(products.added!['minimumStock'], 0);
  });

  testWidgets('editing keeps the stock the ledger built up', (tester) async {
    final products = await _openDialog(tester, product: _product);

    await tester.enterText(find.byType(TextField).at(0), 'CF Blanket 1260C v2');
    await _submit(tester, edit: true);

    expect(products.updated, isNotNull);
    expect(products.updated!['name'], 'CF Blanket 1260C v2');
    // The trap: /products rewrites every field, so these have to be sent
    // back or the edit silently zeroes them.
    expect(products.updated!['currentStock'], 437);
    expect(products.updated!['minimumStock'], 25);
  });
}
