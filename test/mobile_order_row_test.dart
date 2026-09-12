import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/mobile_purchase_layout.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/mobile_sales_layout.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/shared/widgets/mobile_order_row.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The dense Purchase/Sale rows on mobile. What matters here isn't the pixels —
// it's that each row reads out the RIGHT money state: an order that's settled
// says so, and one that isn't shows what's actually left, derived from the
// order's own amount and what's been paid against it.
// ─────────────────────────────────────────────────────────────────────────────

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = const SessionUser(
    id: 1,
    name: 'Chinmay Modi',
    email: 'shc@gmail.com',
    role: 'Super Admin',
    isSuperAdmin: true,
  );
}

class _StubPurchase extends PurchaseController {
  final List<PurchaseOrder> seed;
  _StubPurchase(this.seed);

  @override
  Future<void> fetchStats() async {}

  @override
  Future<void> fetchOrders() async {
    orders.assignAll(seed);
  }
}

class _StubSales extends SalesController {
  final List<SalesOrder> seed;
  _StubSales(this.seed);

  @override
  Future<void> fetchStats() async {}

  @override
  Future<void> fetchOrders() async {
    orders.assignAll(seed);
  }
}

PurchaseOrder _purchase({
  required String po,
  required String supplier,
  required String invoiceNo,
  required String product,
  required double amount,
  double paid = 0,
  PurchaseStatus status = PurchaseStatus.pending,
}) => PurchaseOrder(
  id: po,
  poNumber: po,
  supplier: supplier,
  supplierIcon: '',
  date: DateTime(2026, 7, 10),
  itemCount: 1,
  amount: amount,
  status: status,
  invoiceNo: invoiceNo,
  paidAmount: paid,
  paymentType: paid > 0 ? OrderPaymentType.other : OrderPaymentType.none,
  items: [PurchaseDetailItem(product: product, qty: 10, rate: amount / 10)],
);

SalesOrder _sale({
  required String so,
  required String client,
  required String badge,
  required String product,
  required double amount,
  double paid = 0,
  required PaymentStatus paymentStatus,
}) => SalesOrder(
  id: so,
  soNumber: so,
  client: client,
  clientBadge: badge,
  clientColor: AppColors.primaryOrange,
  date: DateTime(2026, 7, 10),
  itemCount: 1,
  amount: amount,
  status: SalesStatus.confirmed,
  paymentStatus: paymentStatus,
  paidAmount: paid,
  items: [SaleDetailItem(product: product, qty: 120, rate: amount / 120)],
);

Future<void> _pumpMobile(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('mobileRowInitials', () {
    test('takes the first letter of the first two words', () {
      expect(mobileRowInitials('Copper Pipe 15mm'), 'CP');
      expect(mobileRowInitials('Water Heater Coil'), 'WH');
      expect(mobileRowInitials('Suresh Patel'), 'SP');
    });

    test('falls back to the first two letters of a single word', () {
      expect(mobileRowInitials('Maatigraam'), 'MA');
    });

    test('skips leading digits and punctuation rather than badging them', () {
      // "3/4" is a size, not a name — the letters are what identify it.
      expect(mobileRowInitials('Brass Valve 3/4"'), 'BV');
      expect(mobileRowInitials('15mm'), 'MM');
    });

    test('never returns an empty badge', () {
      expect(mobileRowInitials(''), '—');
      expect(mobileRowInitials('123'), '—');
    });
  });

  group('Purchase rows', () {
    testWidgets('a received order reads as Paid; a part-paid one shows the '
        'remaining balance', (tester) async {
      Get.put<PurchaseController>(
        _StubPurchase([
          _purchase(
            po: 'PO-2201',
            supplier: 'Ashoka Metals',
            invoiceNo: 'INV-2201',
            product: 'Copper Pipe 15mm',
            amount: 102000,
            status: PurchaseStatus.received,
          ),
          _purchase(
            po: 'PO-1187',
            supplier: 'Precision Valves Co.',
            invoiceNo: 'INV-1187',
            product: 'Brass Valve 3/4"',
            amount: 16800,
            paid: 10000,
          ),
        ]),
      );
      await _pumpMobile(tester, const MobilePurchaseLayout());

      // Item name titles the row; supplier · invoice identifies it.
      expect(find.text('Copper Pipe 15mm'), findsOneWidget);
      expect(find.text('Ashoka Metals · INV-2201'), findsOneWidget);
      expect(find.text('CP'), findsOneWidget);
      expect(find.text('₹1,02,000'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);

      // 16,800 owed less 10,000 paid = 6,800 still due.
      expect(find.text('Brass Valve 3/4"'), findsOneWidget);
      expect(find.text('Precision Valves Co. · INV-1187'), findsOneWidget);
      expect(find.text('₹6,800 due'), findsOneWidget);
    });

    testWidgets('an unpaid pending order shows its whole amount as due', (
      tester,
    ) async {
      Get.put<PurchaseController>(
        _StubPurchase([
          _purchase(
            po: 'PO-3312',
            supplier: 'Gujarat Polymers',
            invoiceNo: 'INV-3312',
            product: 'PVC Elbow Joint',
            amount: 21000,
          ),
        ]),
      );
      await _pumpMobile(tester, const MobilePurchaseLayout());

      expect(find.text('₹21,000 due'), findsOneWidget);
      expect(find.text('Paid'), findsNothing);
    });

    testWidgets('a cancelled order is called out, not shown as owing money', (
      tester,
    ) async {
      Get.put<PurchaseController>(
        _StubPurchase([
          _purchase(
            po: 'PO-9000',
            supplier: 'Some Supplier',
            invoiceNo: 'INV-9000',
            product: 'Water Heater Coil',
            amount: 14500,
            status: PurchaseStatus.cancelled,
          ),
        ]),
      );
      await _pumpMobile(tester, const MobilePurchaseLayout());

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('₹14,500 due'), findsNothing);
    });
  });

  group('Sale rows', () {
    testWidgets('a paid order reads Received; a partial one shows the '
        'outstanding balance', (tester) async {
      Get.put<SalesController>(
        _StubSales([
          _sale(
            so: 'SO-1',
            client: 'Suresh Patel',
            badge: 'SP',
            product: 'Copper Pipe 15mm',
            amount: 40800,
            paid: 40800,
            paymentStatus: PaymentStatus.paid,
          ),
          _sale(
            so: 'SO-2',
            client: 'Priya Mehta',
            badge: 'PM',
            product: 'Brass Valve 3/4"',
            amount: 6300,
            paid: 3000,
            paymentStatus: PaymentStatus.partial,
          ),
        ]),
      );
      await _pumpMobile(tester, const MobileSalesLayout());

      expect(find.text('Copper Pipe 15mm'), findsOneWidget);
      expect(find.text('Suresh Patel · Qty 120'), findsOneWidget);
      // Sales rows badge by the client, matching the rest of the module.
      // Scoped to the rows: the page's Top Clients card badges by client too,
      // so an unscoped finder would match that as well.
      expect(
        find.descendant(
          of: find.byType(MobileOrderRow),
          matching: find.text('SP'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(MobileOrderRow),
          matching: find.text('₹40,800'),
        ),
        findsOneWidget,
      );
      // Scoped to the rows: "Received" is also one of the page's KPI card
      // labels, so an unscoped finder would match that too.
      expect(
        find.descendant(
          of: find.byType(MobileOrderRow),
          matching: find.text('Received'),
        ),
        findsOneWidget,
      );

      expect(find.text('₹3,300 due'), findsOneWidget);
    });
  });
}
