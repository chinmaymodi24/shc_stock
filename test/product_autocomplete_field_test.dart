import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/product_autocomplete_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The mobile Add Purchase / Add Sale item-name field: this is the widget that
// replaced the framework's `Autocomplete`, specifically because that widget
// always drops its suggestion list BELOW the field — invisible once the field
// is scrolled up to sit against the keyboard. These tests pin down the two
// things that actually matter: it still shows suggestions in the normal case,
// and it flips ABOVE the field once the keyboard leaves no room below.
// ─────────────────────────────────────────────────────────────────────────────

class _StubCategories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
}

class _StubProducts extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {}
}

final _sampleProducts = [
  ProductModel(
    id: '1',
    name: 'Ceramic Fiber Blanket 1260',
    sku: 'CFB-1260',
    categoryId: '1',
    categoryName: 'Ceramic Fiber',
    subCategory: '',
    unit: 'Roll',
    sellingPrice: 4500,
    costPrice: 3800,
    currentStock: 10,
    minimumStock: 2,
    hsnCode: '6806',
    createdAt: DateTime(2026, 1, 1),
  ),
  ProductModel(
    id: '2',
    name: 'Ceramic Fiber Rope 12mm',
    sku: 'CFR-12',
    categoryId: '1',
    categoryName: 'Ceramic Fiber',
    subCategory: '',
    unit: 'Mtr',
    sellingPrice: 120,
    costPrice: 90,
    currentStock: 40,
    minimumStock: 5,
    hsnCode: '6806',
    createdAt: DateTime(2026, 1, 1),
  ),
];

/// A tall scrollable host, with [spacerHeight] of empty space above the field
/// — the same shape as the real item-row form, where the field can sit
/// anywhere from just below the top to deep in the scroll.
Widget _host({required double spacerHeight}) {
  final colors = AppThemeColors.light;
  return MaterialApp(
    theme: ThemeData(extensions: [colors]),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: spacerHeight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ProductAutocompleteField(
                initialValue: '',
                colors: colors,
                priceOf: (p) => p.costPrice,
                onSelected: (_) {},
              ),
            ),
            // Enough trailing space that the field isn't pinned to the very
            // bottom of the scroll content regardless of spacerHeight.
            const SizedBox(height: 400),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    Get.put<CategoriesController>(_StubCategories(), permanent: true);
    final products = _StubProducts();
    Get.put<ProductsController>(products, permanent: true);
    products.products.assignAll(_sampleProducts);
  });

  tearDown(Get.reset);

  testWidgets('shows a suggestion list below the field when there is room', (
    tester,
  ) async {
    await tester.pumpWidget(_host(spacerHeight: 40));

    expect(find.text('Ceramic Fiber Blanket 1260'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ceramic');
    await tester.pumpAndSettle();

    expect(find.text('Ceramic Fiber Blanket 1260'), findsOneWidget);
    expect(find.text('Ceramic Fiber Rope 12mm'), findsOneWidget);

    final fieldRect = tester.getRect(find.byType(TextField));
    final optionRect = tester.getRect(find.text('Ceramic Fiber Blanket 1260'));
    expect(
      optionRect.top,
      greaterThanOrEqualTo(fieldRect.bottom),
      reason: 'suggestions render below the field in the normal case',
    );
  });

  testWidgets(
    'flips the suggestion list above the field once the keyboard covers the '
    'space below it',
    (tester) async {
      // A real device size, and a real keyboard-sized inset on the test's
      // platform view — not a hand-built MediaQueryData, which the ancestor
      // `Scaffold` would consume for its own resize-to-avoid-keyboard and
      // never actually reach this widget (see the fix this test caught: the
      // widget originally read `MediaQuery.of(context)`, which is exactly
      // the copy Scaffold zeroes out).
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      addTearDown(tester.view.reset);

      // `Scaffold.resizeToAvoidBottomInset` (the default) shrinks the body to
      // what's left of the screen once that inset is applied. Bottom-aligning
      // the field inside that shrunk body pins it right above the inset —
      // exactly where a real keyboard leaves a mid-form field once it's
      // scrolled into view, and exactly the position that hid suggestions
      // behind the keyboard before this widget existed.
      final colors = AppThemeColors.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [colors]),
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProductAutocompleteField(
                    initialValue: '',
                    colors: colors,
                    priceOf: (p) => p.costPrice,
                    onSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ceramic');
      await tester.pumpAndSettle();

      expect(find.text('Ceramic Fiber Blanket 1260'), findsOneWidget);

      final fieldRect = tester.getRect(find.byType(TextField));
      final optionRect = tester.getRect(
        find.text('Ceramic Fiber Blanket 1260'),
      );
      expect(
        optionRect.bottom,
        lessThanOrEqualTo(fieldRect.top + 1),
        reason:
            'with no room below, the list must render above the field '
            'instead of disappearing behind the keyboard',
      );
    },
  );

  testWidgets(
    'selecting a suggestion fills the field, fires onSelected once, and '
    'closes the list',
    (tester) async {
      ProductModel? picked;
      final colors = AppThemeColors.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [colors]),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 380,
                child: ProductAutocompleteField(
                  initialValue: '',
                  colors: colors,
                  priceOf: (p) => p.costPrice,
                  onSelected: (p) => picked = p,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'rope');
      await tester.pumpAndSettle();
      expect(find.text('Ceramic Fiber Rope 12mm'), findsOneWidget);

      await tester.tap(find.text('Ceramic Fiber Rope 12mm'));
      await tester.pumpAndSettle();

      expect(picked?.id, '2');
      expect(
        find.widgetWithText(TextField, 'Ceramic Fiber Rope 12mm'),
        findsOneWidget,
      );
      // The list itself is gone — its rows were only findable while showing.
      expect(find.text('HSN 6806 · Mtr'), findsNothing);
    },
  );
}
