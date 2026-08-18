import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/mobile_add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Purchase list's Edit action opens the Add Purchase form with the order
// as the route argument. These pin the hydration: every field the form owns
// comes back, and the identity fields (id / PO number / status) are kept so
// saving updates the record instead of creating a second one.
// ─────────────────────────────────────────────────────────────────────────────

final _order = PurchaseOrder(
  id: '7',
  poNumber: 'PO-2024-10001',
  supplier: 'Amaan Traders',
  supplierIcon: 'AM',
  date: DateTime(2026, 8, 13),
  itemCount: 2,
  amount: 295,
  status: PurchaseStatus.pending,
  supplierAddress: 'Chikhali, Dist. Pune - 411062',
  buyerGst: '27ATXPM3307L1Z2',
  pan: 'ATXPM3307L',
  invoiceNo: 'INV-556',
  invoiceDate: DateTime(2026, 8, 12),
  despatchThrough: 'TRANSPORT',
  lrNo: 'LR-99',
  lrDate: DateTime(2026, 8, 12),
  vehicleNo: 'GJ01AB1234',
  freight: 250,
  placeOfSupply: 'Maharashtra',
  dueDate: DateTime(2026, 9, 1),
  items: const [
    PurchaseDetailItem(
      productId: 4,
      product: 'CF Blanket 1260°C',
      hsn: '6806',
      grade: '1260',
      density: '128',
      qty: 6,
      unit: 'ROLL',
      rate: 40,
    ),
    PurchaseDetailItem(
      product: 'CF Tape',
      hsn: '6806',
      qty: 1,
      unit: 'BOX',
      rate: 55,
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  test('loadFrom fills every form field from the order', () {
    final c = AddPurchaseController()..loadFrom(_order);

    expect(c.isEditing, isTrue);
    expect(c.client.value, 'Amaan Traders');
    expect(c.addressCtrl.text, 'Chikhali, Dist. Pune - 411062');
    expect(c.buyerGstCtrl.text, '27ATXPM3307L1Z2');
    expect(c.panCtrl.text, 'ATXPM3307L');
    expect(c.invoiceNoCtrl.text, 'INV-556');
    expect(c.invoiceDate.value, DateTime(2026, 8, 12));
    expect(c.poNoCtrl.text, 'PO-2024-10001');
    expect(c.despatchThrough.value, 'TRANSPORT');
    expect(c.lrNoCtrl.text, 'LR-99');
    expect(c.vehicleNoCtrl.text, 'GJ01AB1234');
    expect(c.freightCtrl.text, '250.0');
    expect(c.placeOfSupplyCtrl.text, 'Maharashtra');
    expect(c.dueDate.value, DateTime(2026, 9, 1));
  });

  test('item lines come back with their quantities and totals intact', () {
    final c = AddPurchaseController()..loadFrom(_order);

    expect(c.items.length, 2);
    final first = c.items.first;
    expect(first.productId, 4, reason: 'the stock link must survive an edit');
    expect(first.product, 'CF Blanket 1260°C');
    expect(first.hsn, '6806');
    expect(first.uom, 'ROLL');
    expect(first.netPrice, 40);
    // qty is stored as one number and split back into packs x per-pack.
    expect(first.totalQty, 6);
    expect(first.amount, 240);

    // Same subtotal the order was saved with (295 = 240 + 55).
    expect(c.subTotal, 295);
  });

  group('total qty is editable', () {
    test('setting a total back-solves the pack count', () {
      final row = PurchaseItemRow()
        ..noPkg = 2
        ..avgContPerPkg = 5
        ..netPrice = 10;
      expect(row.totalQty, 10);

      row.totalQty = 25;

      // Per-pack is kept and packs are re-derived, so the three boxes agree.
      expect(row.avgContPerPkg, 5);
      expect(row.noPkg, 5);
      expect(row.totalQty, 25);
      expect(row.amount, 250);
    });

    test('a plain quantity can be typed straight in', () {
      final row = PurchaseItemRow()..netPrice = 40;
      row.totalQty = 7;
      expect(row.totalQty, 7);
      expect(row.noPkg, 7, reason: 'per-pack is 1, so packs carry the total');
      expect(row.amount, 280);
    });

    test(
      'negatives floor at zero and a zero per-pack cannot divide by zero',
      () {
        final row = PurchaseItemRow()..avgContPerPkg = 0;
        row.totalQty = 4;
        expect(row.avgContPerPkg, 1);
        expect(row.totalQty, 4);

        row.totalQty = -3;
        expect(row.totalQty, 0);
      },
    );
  });

  test('a new purchase is not in edit mode', () {
    final c = AddPurchaseController();
    expect(c.isEditing, isFalse);
    expect(c.editing, isNull);
    expect(c.items.length, 1, reason: 'starts with one blank row');
  });

  test('an order with no saved lines still opens with a usable blank row', () {
    final c = AddPurchaseController()
      ..loadFrom(
        PurchaseOrder(
          id: '9',
          poNumber: 'PO-2024-10009',
          supplier: 'Ashoka Metals',
          supplierIcon: 'AM',
          date: DateTime(2026, 8, 1),
          itemCount: 0,
          amount: 0,
          status: PurchaseStatus.received,
        ),
      );

    expect(c.items.length, 1);
    expect(c.items.single.product, '');
    // The row defaults still hold, so a freshly picked product prices itself.
    expect(c.items.single.noPkg, 1);
    expect(c.items.single.avgContPerPkg, 1);
  });

  group('the quantity stepper widget', () {
    /// Drives the stepper the way the item row does: value in, value out.
    Future<void> pumpStepper(WidgetTester tester, ValueNotifier<double> qty) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.light]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                child: ValueListenableBuilder<double>(
                  valueListenable: qty,
                  builder: (context, v, _) => AppSmallStepper(
                    value: v,
                    colors: AppThemeColors.light,
                    onChanged: (next) => qty.value = next,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('+ and - move the value and the box follows', (tester) async {
      final qty = ValueNotifier<double>(1);
      addTearDown(qty.dispose);
      await pumpStepper(tester, qty);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(qty.value, 2);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(qty.value, 1);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('- stops at zero instead of going negative', (tester) async {
      final qty = ValueNotifier<double>(1);
      addTearDown(qty.dispose);
      await pumpStepper(tester, qty);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(qty.value, 0);

      // Disabled at the floor — tapping again changes nothing.
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(qty.value, 0);
    });

    testWidgets('a typed quantity is reported straight through', (
      tester,
    ) async {
      final qty = ValueNotifier<double>(1);
      addTearDown(qty.dispose);
      await pumpStepper(tester, qty);

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      expect(qty.value, 12);
    });
  });

  test('the mobile row shares the same editable total', () {
    final row = MobilePurchaseItemRow()
      ..avgContPerPkg = 4
      ..netPrice = 25;
    row.totalQty = 12;
    expect(row.noPkg, 3);
    expect(row.totalQty, 12);
    expect(row.amount, 300);
  });

  test('the form leaves by route, not by popping the stack', () {
    // Opening /purchase/add directly (a bookmark, a hot restart, or the
    // browser URL bar) leaves nothing to pop — Cancel and the back arrow
    // have to name the list route or they do nothing at all.
    final source = File(
      'lib/app/modules/purchase/views/web_new_purchase_layout.dart',
    ).readAsStringSync();

    expect(
      source.contains('Get.back()'),
      isFalse,
      reason: 'back arrow / Cancel / post-save must not rely on a pop',
    );
    expect(source.contains('Get.offNamed(AppRoutes.purchase)'), isTrue);
  });
}
