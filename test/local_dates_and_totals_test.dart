import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';

// The server stores instants in UTC ("…Z"). Read as UTC, an order dated in the
// evening-before-midnight of UTC showed the wrong calendar day and the wrong
// clock time for anyone east of Greenwich. Every parsed date is now local.

PurchaseOrder _po(
  String id, {
  double amount = 1000,
  double paid = 0,
  String status = 'Pending',
}) => PurchaseOrder.fromJson({
  'id': int.parse(id),
  'poNumber': 'PO-$id',
  'supplier': 'S',
  'date': '2026-10-08T18:30:00.000Z',
  'expectedDelivery': '2026-10-09T18:30:00.000Z',
  'amount': amount,
  'paidAmount': paid,
  'status': status,
  'items': <dynamic>[],
});

void main() {
  tearDown(Get.reset);

  test('parsed dates are local instants, not UTC', () {
    final p = _po('1');
    expect(p.date.isUtc, isFalse);
    expect(p.expectedDelivery!.isUtc, isFalse);
    expect(p.date, DateTime.parse('2026-10-08T18:30:00.000Z').toLocal());

    final t = TransactionModel.fromJson({
      'id': 1,
      'item': 'x',
      'type': 'Inbound',
      'status': 'Pending',
      'date': '2026-10-08T18:30:00.000Z',
      'modifiedAt': '2026-10-09T02:46:00.000Z',
    });
    expect(t.date.isUtc, isFalse);
    expect(t.modifiedAt.isUtc, isFalse);
  });

  test('the purchase rail splits paid / due by what was actually paid', () {
    final c = PurchaseController();
    c.orders.assignAll([
      _po('1', amount: 1000, paid: 1000), // fully paid, still on its way
      _po('2', amount: 500, paid: 200),
      _po('3', amount: 700, paid: 0, status: 'Cancelled'), // counts for neither
    ]);
    expect(c.totalAmountPaid, 1200);
    expect(c.totalAmountDue, 300);
  });

  test('purchase and sale invoice numbering are switched separately', () async {
    SharedPreferences.setMockInitialValues({
      kAutoNumberPurchasePrefKey: false,
      kAutoNumberSalesPrefKey: true,
    });
    expect(await autoNumberPurchaseEnabled(), isFalse);
    expect(await autoNumberSalesEnabled(), isTrue);
    SharedPreferences.setMockInitialValues({});
    expect(await autoNumberPurchaseEnabled(), isTrue, reason: 'default is on');
    expect(await autoNumberSalesEnabled(), isTrue);
  });
}
