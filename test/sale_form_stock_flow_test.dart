import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/web_new_sales_layout.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'support/session.dart';

// The Add Sale form, driven the way a person drives it: search a product, see
// whether it is in stock, add quantity, hit the limit, try to save.

ProductModel _p(
  String id,
  String name,
  int stock, {
  int committed = 0,
  String status = '',
  bool active = true,
}) => ProductModel(
  id: id,
  name: name,
  sku: 'SKU-$id',
  categoryId: '1',
  categoryName: 'Cat',
  subCategory: 'Sub',
  unit: 'PCS',
  sellingPrice: 100,
  costPrice: 60,
  currentStock: stock.toDouble(),
  committedStock: committed.toDouble(),
  isActive: active,
  minimumStock: 0,
  serverStockStatus: status,
  hsnCode: '6902',
  createdAt: DateTime(2026, 1, 1),
);

class _Products extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {
    products.assignAll([
      _p('1', 'Brick Five', 5),
      _p('2', 'Brick Zero', 0, status: 'outOfStock'),
      _p('3', 'Brick Held', 10, committed: 8),
      _p('4', 'Brick Low', 3, status: 'lowStock'),
      _p('5', 'Brick Retired', 9, status: 'inactive', active: false),
    ]);
  }
}

class _Categories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

class _Clients extends ClientsController {
  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.empty;
  }

  @override
  Future<void> fetchClients() async {}
}

/// Records what the form tried to save instead of calling the API.
class _Sales extends SalesController {
  final saved = <SalesOrder>[];
  @override
  Future<void> fetchOrders() async {}
  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.empty;
  }

  @override
  Future<bool> addOrder(SalesOrder order) async {
    saved.add(order);
    return true;
  }
}

late _Sales _sales;
late AddSaleController _form;

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1600, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  signInSuperAdmin();
  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<CategoriesController>(_Categories(), permanent: true);
  Get.put<ProductsController>(_Products(), permanent: true);
  Get.put<ClientsController>(_Clients(), permanent: true);
  _sales = Get.put<SalesController>(_Sales(), permanent: true) as _Sales;
  _form = Get.put(AddSaleController());
  _form.client.value = 'Aavkar Enterprise';

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: const WebNewSalesLayout(),
      // A successful save navigates to the Sales list.
      getPages: [GetPage(name: '/sales', page: () => const SizedBox())],
    ),
  );
  await tester.pumpAndSettle();
}

/// Types into the first item search box and picks the suggestion.
Future<void> _pick(WidgetTester tester, String query, String option) async {
  final box = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
  );
  await tester.enterText(box.first, query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// A toast keeps a 3-second timer; let it run out so the test can end cleanly.
void flowTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    // Toasts queue one after another, each holding a 3-second timer.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  });
}

void main() {
  tearDown(Get.reset);

  flowTest('the suggestions say what is in stock before anything is picked', (
    tester,
  ) async {
    await _pump(tester);
    final box = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
    );
    await tester.enterText(box.first, 'Brick');
    await tester.pumpAndSettle();

    expect(find.text('Brick Five'), findsOneWidget);
    expect(find.text('5 in stock'), findsOneWidget);
    // Nothing left to sell: listed, but with the reason inside the dropdown.
    expect(find.text('Not in stock — nothing to sell'), findsOneWidget);
    // 10 on the shelf but 8 promised to open sales: only 2 are free.
    expect(find.text('2 free'), findsOneWidget);
    expect(find.text('Low · 3 left'), findsOneWidget);
    // An inactive product is retired from new orders.
    expect(find.text('Brick Retired'), findsNothing);
  });

  flowTest('an out-of-stock product cannot be picked and says why in the list', (
    tester,
  ) async {
    await _pump(tester);
    final box = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
    );
    await tester.enterText(box.first, 'Brick Zero');
    await tester.pumpAndSettle();
    expect(find.text('Not in stock — nothing to sell'), findsOneWidget);

    await tester.tap(find.text('Brick Zero').last);
    await tester.pumpAndSettle();

    // Nothing was picked: no record on the row, the typed text is left alone.
    expect(_form.items.first.productId, isNull);
    expect(_form.items.first.hsn, isEmpty);
    expect(_form.items.first.rate, 0);
    expect(find.text('Not in stock — nothing to sell'), findsOneWidget);
    expect(_sales.saved, isEmpty);
  });

  flowTest('a low-stock product gets an amber heads-up but can be sold', (
    tester,
  ) async {
    await _pump(tester);
    await _pick(tester, 'Brick Low', 'Brick Low');

    // Once under the row, once in the toast.
    expect(find.textContaining('Low stock — only 3 PCS left'), findsWidgets);
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();
    expect(_sales.saved.length, 1);
    expect(_sales.saved.single.items.single.productId, 4);
  });

  flowTest('stock 5: + stops at 5 and says only 5 are available', (
    tester,
  ) async {
    await _pump(tester);
    await _pick(tester, 'Brick Five', 'Brick Five');
    expect(_form.items.first.qty, 1);

    final plus = find.descendant(
      of: find.byType(AppSmallStepper),
      matching: find.byIcon(Icons.add_rounded),
    );
    for (var i = 0; i < 8; i++) {
      await tester.tap(plus.first);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(_form.items.first.qty, 5, reason: 'capped at the stock, not 9');
    expect(
      find.textContaining('Only 5 PCS of "Brick Five" available.'),
      findsWidgets,
    );
  });

  flowTest('typing more than is free is pulled back to what is free', (
    tester,
  ) async {
    await _pump(tester);
    await _pick(tester, 'Brick Held', 'Brick Held');

    // 10 in stock, 8 promised elsewhere -> 2 can be sold.
    final qty = find.descendant(
      of: find.byType(AppSmallStepper),
      matching: find.byType(TextField),
    );
    await tester.enterText(qty.first, '7');
    await tester.pumpAndSettle();

    expect(_form.items.first.qty, 2);
  });

  flowTest('a sale within stock saves, with the product id', (tester) async {
    await _pump(tester);
    await _pick(tester, 'Brick Five', 'Brick Five');

    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();

    expect(_sales.saved.length, 1);
    final line = _sales.saved.single.items.single;
    expect(line.productId, 1); // "Brick Five"
    expect(line.qty, 1);
  });

  flowTest('an empty form is not saved', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();
    expect(_sales.saved, isEmpty);
  });

  flowTest('a name typed by hand is kept and saved as a free line', (
    tester,
  ) async {
    await _pump(tester);
    final box = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
    );
    await tester.enterText(box.first, 'Special anchor');
    await tester.pumpAndSettle();
    expect(_form.items.first.product, 'Special anchor');
    expect(_form.items.first.productId, isNull);

    final qty = find.descendant(
      of: find.byType(AppSmallStepper),
      matching: find.byType(TextField),
    );
    await tester.enterText(qty.first, '3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();

    expect(_sales.saved.length, 1);
    final line = _sales.saved.single.items.single;
    expect(line.product, 'Special anchor');
    expect(line.productId, isNull);
    expect(line.qty, 3);
    // The toast says inventory will not move for it.
    expect(find.textContaining('not linked to a product'), findsWidgets);
  });

  flowTest('typing over a picked product unlinks it from inventory', (
    tester,
  ) async {
    await _pump(tester);
    await _pick(tester, 'Brick Five', 'Brick Five');
    expect(_form.items.first.productId, 1);

    final box = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
    );
    await tester.enterText(box.first, 'Brick Five special');
    await tester.pumpAndSettle();
    expect(_form.items.first.productId, isNull);
    expect(_form.items.first.product, 'Brick Five special');
  });

  flowTest('a client name typed by hand (not in the list) is kept', (
    tester,
  ) async {
    await _pump(tester);
    _form.client.value = '';
    await tester.pumpAndSettle();
    final clientBox = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText ?? '') == 'Type to search client...',
    );
    await tester.enterText(clientBox.first, 'Walk-in Buyer');
    await tester.pumpAndSettle();
    expect(_form.client.value, 'Walk-in Buyer');

    await _pick(tester, 'Brick Five', 'Brick Five');
    await tester.tap(find.text('Save Sale'));
    await tester.pumpAndSettle();
    expect(_sales.saved.single.client, 'Walk-in Buyer');
  });
}
