import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sales mirrors Purchase: the list's Edit action opens the Add Sale form with
// the order as the route argument, and saving updates that record rather than
// creating a second one.
// ─────────────────────────────────────────────────────────────────────────────

final _order = SalesOrder(
  id: '12',
  soNumber: 'SO-2024-10004',
  client: 'Aavkar Enterprise',
  clientBadge: 'AE',
  clientColor: const Color(0xFFF47B20),
  date: DateTime(2026, 8, 10),
  itemCount: 2,
  amount: 4720,
  status: SalesStatus.confirmed,
  paymentStatus: PaymentStatus.partial,
  clientAddress: 'Ramnagar, Sabarmati, Ahmedabad - 380005',
  buyerGstin: '24AQTPM1621J1ZP',
  pan: 'AQTPM1621J',
  invoiceNo: 'INV-2041',
  invoiceDate: DateTime(2026, 8, 9),
  despatchedThrough: 'TRANSPORT',
  destination: 'Gujarat',
  items: const [
    SaleDetailItem(
      productId: 8,
      product: 'CF Blanket 1260°C',
      hsn: '6806',
      qty: 4,
      unit: 'ROLL',
      rate: 1000,
    ),
    SaleDetailItem(
      product: 'CF Tape',
      hsn: '6806',
      qty: 2,
      unit: 'BOX',
      rate: 360,
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  test('loadFrom fills the form from the order', () {
    final c = AddSaleController()..loadFrom(_order);

    expect(c.isEditing, isTrue);
    expect(c.client.value, 'Aavkar Enterprise');
    expect(c.addressCtrl.text, 'Ramnagar, Sabarmati, Ahmedabad - 380005');
    expect(c.buyerGstCtrl.text, '24AQTPM1621J1ZP');
    expect(c.panCtrl.text, 'AQTPM1621J');
    expect(c.invoiceNoCtrl.text, 'INV-2041');
    expect(c.invoiceDate.value, DateTime(2026, 8, 9));
    expect(c.poNoCtrl.text, 'SO-2024-10004');
    expect(c.despatchThrough.value, 'TRANSPORT');
    expect(c.placeOfSupplyCtrl.text, 'Gujarat');
  });

  test('item lines come back with their quantities and totals intact', () {
    final c = AddSaleController()..loadFrom(_order);

    expect(c.items.length, 2);
    final first = c.items.first;
    expect(first.productId, 8, reason: 'the stock link must survive an edit');
    expect(first.product, 'CF Blanket 1260°C');
    expect(first.unit, 'ROLL');
    expect(first.qty, 4);
    expect(first.amount, 4000);

    // 4000 + 720, the taxable value the order was saved with.
    expect(c.taxableValue, 4720);
  });

  test('a new sale is not in edit mode', () {
    final c = AddSaleController();
    expect(c.isEditing, isFalse);
    expect(c.editing, isNull);
    expect(c.items.length, 1, reason: 'starts with one blank row');
  });

  test('an order with no saved lines still opens with a blank row', () {
    final c = AddSaleController()
      ..loadFrom(
        SalesOrder(
          id: '3',
          soNumber: 'SO-2024-10003',
          client: 'Amaan Traders',
          clientBadge: 'AT',
          clientColor: const Color(0xFF3B82F6),
          date: DateTime(2026, 8, 1),
          itemCount: 0,
          amount: 0,
          status: SalesStatus.confirmed,
          paymentStatus: PaymentStatus.pending,
        ),
      );

    expect(c.items.length, 1);
    expect(c.items.single.product, '');
  });

  test('the form leaves by route, not by popping the stack', () {
    final source = File(
      'lib/app/modules/sales/views/web_new_sales_layout.dart',
    ).readAsStringSync();

    expect(
      source.contains('Get.back()'),
      isFalse,
      reason: 'back arrow / Cancel / post-save must not rely on a pop',
    );
    expect(source.contains('Get.offNamed(AppRoutes.sales)'), isTrue);
  });

  group('the Items column counts units, not lines', () {
    test('a single 5-unit line reads 5, matching the form', () {
      final order = SalesOrder(
        id: '1',
        soNumber: 'SO-2024-10001',
        client: 'New Client',
        clientBadge: 'NE',
        clientColor: const Color(0xFFF47B20),
        date: DateTime(2026, 8, 14),
        itemCount: 1,
        amount: 2065,
        status: SalesStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
        items: const [
          SaleDetailItem(product: 'CF Bulk', qty: 5, unit: 'kg', rate: 350),
        ],
      );

      expect(order.totalQty, 5);
      expect(order.totalQtyLabel, '5');
      expect(order.itemCount, 1, reason: 'still one line behind that 5');
    });

    test('quantities add up across lines, and fractions survive', () {
      final order = SalesOrder(
        id: '2',
        soNumber: 'SO-2024-10002',
        client: 'Amaan Traders',
        clientBadge: 'AT',
        clientColor: const Color(0xFF3B82F6),
        date: DateTime(2026, 8, 14),
        itemCount: 2,
        amount: 0,
        status: SalesStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
        items: const [
          SaleDetailItem(product: 'A', qty: 2.5, unit: 'kg', rate: 10),
          SaleDetailItem(product: 'B', qty: 1, unit: 'BOX', rate: 10),
        ],
      );

      expect(order.totalQty, 3.5);
      expect(order.totalQtyLabel, '3.50');
    });

    test('an order saved without its lines falls back to the line count', () {
      final order = SalesOrder(
        id: '3',
        soNumber: 'SO-2024-10003',
        client: 'Old Record',
        clientBadge: 'OR',
        clientColor: const Color(0xFF3B82F6),
        date: DateTime(2026, 1, 1),
        itemCount: 4,
        amount: 0,
        status: SalesStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
      );

      expect(order.totalQtyLabel, '4');
    });
  });
}
