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
import 'package:shc_stock/app/modules/sales/models/sale_payment.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/mobile_add_sales_layout.dart';
import 'package:shc_stock/app/modules/sales/views/web_new_sales_layout.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';
import 'support/session.dart';

// Several payments on one sale: the form's "Payments" rows (web and mobile),
// what gets sent, and how the rows come back from the API and into the
// Transactions list.

ProductModel _p(String id, String name, int stock) => ProductModel(
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
  isActive: true,
  minimumStock: 0,
  hsnCode: '6902',
  createdAt: DateTime(2026, 1, 1),
);

class _Products extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {
    products.assignAll([_p('1', 'Brick Five', 50)]);
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

  @override
  Future<bool> updateOrder(SalesOrder order) async {
    saved.add(order);
    return true;
  }
}

late _Sales _sales;
late AddSaleController _form;

Future<void> _pump(
  WidgetTester tester, {
  bool mobile = false,
  Object? arguments,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = mobile
      ? const Size(390, 2600)
      : const Size(1600, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  signInSuperAdmin();
  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<CategoriesController>(_Categories(), permanent: true);
  Get.put<ProductsController>(_Products(), permanent: true);
  Get.put<ClientsController>(_Clients(), permanent: true);
  _sales = Get.put<SalesController>(_Sales(), permanent: true) as _Sales;

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: const SizedBox(),
      getPages: [
        GetPage(
          name: '/add',
          page: () => mobile
              ? const MobileAddSalesLayout()
              : const WebNewSalesLayout(),
          // As SalesBinding does: lazy, and owned by the route — so leaving
          // the page runs onClose, exactly like the app.
          binding: BindingsBuilder(
            () => Get.lazyPut<AddSaleController>(() => AddSaleController()),
          ),
        ),
        GetPage(name: '/sales', page: () => const SizedBox()),
      ],
    ),
  );
  // Open the form the way the list's Add / Edit actions do.
  Get.toNamed('/add', arguments: arguments);
  await tester.pumpAndSettle();
  _form = Get.find<AddSaleController>();
  _form.client.value = 'Aavkar Enterprise';
}

/// Picks "Brick Five" on the first item row: 1 x ₹100 + 18% GST = ₹118.
Future<void> _pickBrick(WidgetTester tester) async {
  final box = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        (w.decoration?.hintText ?? '').startsWith('Type e.g.'),
  );
  await tester.enterText(box.first, 'Brick');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Brick Five').last);
  await tester.pumpAndSettle();
}

Finder _amountBoxes() => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'e.g. 5000',
);

Future<void> _save(WidgetTester tester, {String label = 'Save Sale'}) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// A toast holds a timer; let them run out so the test ends cleanly.
void flowTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  });
}

void main() {
  tearDown(Get.reset);

  group('checkPaymentRows', () {
    test('an untouched empty row is ignored', () {
      expect(checkPaymentRows([(amount: '', notes: '')], total: 100), isNull);
    });
    test('a row with a note but no amount is refused', () {
      expect(
        checkPaymentRows([(amount: '', notes: 'cheque')], total: 100),
        contains('Payment 1'),
      );
    });
    test('zero or junk is refused, naming the row', () {
      expect(
        checkPaymentRows([
          (amount: '50', notes: ''),
          (amount: '0', notes: ''),
        ], total: 100),
        contains('Payment 2'),
      );
    });
    test('the rows may not add up to more than the total', () {
      expect(
        checkPaymentRows([
          (amount: '60', notes: ''),
          (amount: '60', notes: ''),
        ], total: 100),
        contains('more than the sale total'),
      );
      // A rupee of slack for on-screen rounding.
      expect(
        checkPaymentRows([(amount: '100.80', notes: '')], total: 100),
        isNull,
      );
    });
  });

  group('JSON', () {
    test('a sale reads its payments and sends them back', () {
      final order = SalesOrder.fromJson({
        'id': 7,
        'soNumber': 'SO/0007/26-27',
        'client': 'A',
        'date': '2026-10-12T00:00:00.000Z',
        'amount': 1180,
        'paidAmount': 800,
        'paymentStatus': 'Partial',
        'items': [],
        'payments': [
          {
            'id': 1,
            'date': '2026-10-12T00:00:00.000Z',
            'amount': 500,
            'mode': 'Cash',
            'notes': 'advance',
          },
          {
            'id': 2,
            'date': '2026-10-13T00:00:00.000Z',
            'amount': 300,
            'mode': 'UPI',
          },
        ],
      });
      expect(order.payments.length, 2);
      expect(order.payments.first.amount, 500);
      expect(order.payments.first.notes, 'advance');
      expect(order.payments.last.mode, 'UPI');

      final sent = order.toCreateJson()['payments'] as List;
      expect(sent.length, 2);
      expect((sent.first as Map)['amount'], 500);
      expect((sent.first as Map)['mode'], 'Cash');
    });

    test('a Transactions row knows it came from a sale', () {
      final t = TransactionModel.fromJson({
        'id': 3,
        'item': 'Brick',
        'type': 'Outbound',
        'party': 'A',
        'poNumber': 'SO/0007/26-27',
        'date': '2026-10-12T00:00:00.000Z',
        'status': 'Received',
        'amount': 500,
        'mode': 'Cash',
        'refType': 'sale',
        'modifiedAt': '2026-10-12T00:00:00.000Z',
      });
      expect(t.amount, 500);
      expect(t.mode, 'Cash');
      expect(t.isLinked, isTrue);
      expect(t.sourceLabel, 'Sale');

      final handEntered = TransactionModel.fromJson({
        'id': 4,
        'item': 'x',
        'date': '2026-10-12T00:00:00.000Z',
        'modifiedAt': '2026-10-12T00:00:00.000Z',
      });
      expect(handEntered.isLinked, isFalse);
      expect(handEntered.amount, 0);
    });
  });

  flowTest('web: a new sale starts paid in full, following the total', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Payments'), findsOneWidget);
    await _pickBrick(tester);

    expect(_form.payments.length, 1);
    expect(_form.payments.single.amountCtrl.text, '118');
    expect(_form.balanceDue, 0);
    expect(_form.paymentStatusPreview, PaymentStatus.paid);

    await _save(tester);
    final sale = _sales.saved.single;
    expect(sale.payments.length, 1);
    expect(sale.payments.single.amount, 118);
    expect(sale.payments.single.mode, 'Cash');
    expect(sale.paidAmount, 118);
    expect(sale.paymentStatus, PaymentStatus.paid);
  });

  flowTest('web: two payments — the second is offered what is still due', (
    tester,
  ) async {
    await _pump(tester);
    await _pickBrick(tester);

    // The client paid ₹50 now…
    await tester.enterText(_amountBoxes().first, '50');
    await tester.pumpAndSettle();
    expect(_form.balanceDue, 68);
    expect(find.text('Partial'), findsOneWidget);

    // …and "Add Payment" offers the ₹68 left.
    await tester.ensureVisible(find.text('Add Payment'));
    await tester.tap(find.text('Add Payment'));
    await tester.pumpAndSettle();
    expect(_form.payments.length, 2);
    expect(_form.payments.last.amountCtrl.text, '68');
    _form.setPaymentMode(_form.payments.last, 'UPI');
    await tester.enterText(
      find
          .byWidgetPredicate(
            (w) =>
                w is TextField &&
                (w.decoration?.hintText ?? '').startsWith('Optional — cheque'),
          )
          .last,
      'UTR 12345',
    );
    await tester.pumpAndSettle();

    await _save(tester);
    final sale = _sales.saved.single;
    expect(sale.payments.map((p) => p.amount), [50, 68]);
    expect(sale.payments.last.mode, 'UPI');
    expect(sale.payments.last.notes, 'UTR 12345');
    expect(sale.paidAmount, 118);
    expect(sale.paymentStatus, PaymentStatus.paid);
  });

  flowTest('web: changing the items no longer moves a typed amount', (
    tester,
  ) async {
    await _pump(tester);
    await _pickBrick(tester);
    await tester.enterText(_amountBoxes().first, '100');
    await tester.pumpAndSettle();
    _form.items.first.qty = 2;
    _form.notifyItemsChanged();
    await tester.pumpAndSettle();
    expect(_form.payments.single.amountCtrl.text, '100');
    expect(_form.balanceDue, 136);
  });

  flowTest('web: no payments saves as Pending', (tester) async {
    await _pump(tester);
    await _pickBrick(tester);
    await tester.tap(find.byTooltip('Remove payment'));
    await tester.pumpAndSettle();
    expect(_form.payments, isEmpty);
    expect(find.textContaining('No payment recorded yet'), findsOneWidget);

    await _save(tester);
    final sale = _sales.saved.single;
    expect(sale.payments, isEmpty);
    expect(sale.paidAmount, 0);
    expect(sale.paymentStatus, PaymentStatus.pending);
  });

  flowTest('web: payments above the total are stopped before saving', (
    tester,
  ) async {
    await _pump(tester);
    await _pickBrick(tester);
    await tester.enterText(_amountBoxes().first, '500');
    await tester.pumpAndSettle();
    expect(
      find.text('The payments add up to more than the grand total.'),
      findsOneWidget,
    );
    await _save(tester);
    expect(_sales.saved, isEmpty);
    expect(find.textContaining('more than the sale total'), findsWidgets);
  });

  flowTest('edit: the saved payments come back as rows', (tester) async {
    final order = SalesOrder(
      id: '9',
      soNumber: 'SO/0009/26-27',
      client: 'Aavkar Enterprise',
      clientBadge: 'AA',
      clientColor: Colors.orange,
      date: DateTime(2026, 10, 1),
      itemCount: 1,
      amount: 118,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 80,
      items: [
        SaleDetailItem(
          productId: 1,
          product: 'Brick Five',
          hsn: '6902',
          qty: 1,
          unit: 'PCS',
          rate: 100,
          taxPercent: 18,
        ),
      ],
      payments: [
        SalePayment(date: DateTime(2026, 10, 1), amount: 50, mode: 'Cash'),
        SalePayment(date: DateTime(2026, 10, 5), amount: 30, mode: 'UPI'),
      ],
    );
    await _pump(tester, arguments: order);
    expect(_form.isEditing, isTrue);
    expect(_form.payments.length, 2);
    expect(_form.payments.last.mode.value, 'UPI');
    expect(_form.paidAmount, 80);
    expect(_form.balanceDue, 38);
  });

  flowTest('edit: an older sale with only a paid total gets one row', (
    tester,
  ) async {
    final order = SalesOrder(
      id: '10',
      soNumber: 'SO/0010/26-27',
      client: 'Aavkar Enterprise',
      clientBadge: 'AA',
      clientColor: Colors.orange,
      date: DateTime(2026, 9, 1),
      itemCount: 0,
      amount: 500,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.partial,
      paidAmount: 200,
    );
    await _pump(tester, arguments: order);
    expect(_form.payments.length, 1);
    expect(_form.payments.single.amount, 200);
    expect(_form.payments.single.date.value, DateTime(2026, 9, 1));
  });

  flowTest('mobile: payments are cards, and Add offers what is due', (
    tester,
  ) async {
    await _pump(tester, mobile: true);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Payment 1'), findsOneWidget);

    await _pickBrick(tester);
    await tester.enterText(_amountBoxes().first, '18');
    await tester.pumpAndSettle();

    // The section's own "Add" pill — the second one on the page.
    final addPills = find.byType(AppAddRowPill);
    await tester.ensureVisible(addPills.last);
    await tester.tap(addPills.last);
    await tester.pumpAndSettle();
    expect(find.text('Payment 2'), findsOneWidget);
    expect(_form.payments.last.amountCtrl.text, '100');
    expect(_form.balanceDue, 0);

    await _save(tester);
    final sale = _sales.saved.single;
    expect(sale.payments.map((p) => p.amount), [18, 100]);
    expect(sale.paymentStatus, PaymentStatus.paid);
  });
  flowTest('mobile: a refused save, then a good one, leaves cleanly', (
    tester,
  ) async {
    await _pump(tester, mobile: true);
    await _pickBrick(tester);
    await tester.enterText(_amountBoxes().first, '30');
    await tester.pumpAndSettle();
    final addPills = find.byType(AppAddRowPill);
    await tester.ensureVisible(addPills.last);
    await tester.tap(addPills.last);
    await tester.pumpAndSettle();
    _form.setPaymentMode(_form.payments.last, 'Cheque');
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.hintText ?? '').startsWith('Optional — cheque'),
      ).last,
      'CHQ-4521',
    );
    await tester.enterText(_amountBoxes().last, '200');
    await tester.pumpAndSettle();
    await _save(tester);
    expect(_sales.saved, isEmpty);
    await tester.enterText(_amountBoxes().last, '88');
    await tester.pumpAndSettle();
    await _save(tester);
    expect(_sales.saved.single.payments.map((p) => p.amount), [30, 88]);
    // Leaving the page disposed the form, as in the app.
    await tester.pump(const Duration(seconds: 1));
    expect(Get.isRegistered<AddSaleController>(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
