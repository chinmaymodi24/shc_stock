import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';

// Mirrors the exact wiring used by the Item Details table in
// web_new_purchase_layout.dart: an Obx over controller.items rendering
// AppSmallNumber cells that mutate the row then call notifyItemsChanged(),
// plus a second Obx reading the derived totals.
Widget _harness(AddPurchaseController c) {
  const colors = AppThemeColors.light;
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Obx(
            () => Column(
              children: c.items
                  .map(
                    (row) => Row(
                      children: [
                        Expanded(
                          child: AppSmallNumber(
                            key: const Key('noPkg'),
                            value: row.noPkg,
                            colors: colors,
                            onChanged: (v) {
                              row.noPkg = v;
                              c.notifyItemsChanged();
                            },
                          ),
                        ),
                        Expanded(
                          child: AppSmallNumber(
                            key: const Key('avgCont'),
                            value: row.avgContPerPkg,
                            colors: colors,
                            onChanged: (v) {
                              row.avgContPerPkg = v;
                              c.notifyItemsChanged();
                            },
                          ),
                        ),
                        Expanded(
                          child: AppSmallNumber(
                            key: ValueKey('netPrice_${row.version}'),
                            value: row.netPrice,
                            colors: colors,
                            decimal: true,
                            onChanged: (v) {
                              row.netPrice = v;
                              c.notifyItemsChanged();
                            },
                          ),
                        ),
                        Text(
                          'AMT:${row.amount.toStringAsFixed(0)}',
                          key: const Key('amount'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          Obx(
            () => Text(
              'SUB:${c.subTotal.toStringAsFixed(0)}',
              key: const Key('sub'),
            ),
          ),
          Obx(
            () => Text(
              'GT:${c.grandTotal.toStringAsFixed(0)}',
              key: const Key('gt'),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('amount and totals recompute as qty / net price are typed', (
    tester,
  ) async {
    final c = Get.put(AddPurchaseController());
    await tester.pumpWidget(_harness(c));

    await tester.enterText(find.byKey(const ValueKey('netPrice_0')), '48');
    await tester.pump();

    // Net price alone must already move the amount: a new row defaults to
    // 1 pkg x 1 per pkg, so the price is never swallowed by a zero quantity.
    expect(tester.widget<Text>(find.byKey(const Key('amount'))).data, 'AMT:48');
    expect(tester.widget<Text>(find.byKey(const Key('sub'))).data, 'SUB:48');

    await tester.enterText(find.byKey(const Key('noPkg')), '2');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('avgCont')), '3');
    await tester.pump();

    expect(c.items.first.totalQty, 6);
    expect(c.items.first.amount, 288);
    expect(
      tester.widget<Text>(find.byKey(const Key('amount'))).data,
      'AMT:288',
    );
    expect(tester.widget<Text>(find.byKey(const Key('sub'))).data, 'SUB:288');
    // 288 + 9% + 9% = 339.84
    expect(tester.widget<Text>(find.byKey(const Key('gt'))).data, 'GT:340');
  });

  testWidgets('product autofill re-seeds the net price box', (tester) async {
    final c = Get.put(AddPurchaseController());
    await tester.pumpWidget(_harness(c));

    // Simulate what _applyProduct does on product selection.
    c.items.first.netPrice = 38;
    c.items.first.version++;
    c.notifyItemsChanged();
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).at(2),
    );
    expect(field.initialValue, '38.00');
    expect(
      find.text('38.00'),
      findsOneWidget,
      reason: 'net price box must display the autofilled product price',
    );
  });
}
