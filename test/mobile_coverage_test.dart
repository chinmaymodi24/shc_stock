import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/shared/widgets/export/export_overlay_host.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/bill_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/views/bill_view.dart';
import 'package:shc_stock/app/modules/billing/widgets/thermal_receipt.dart';
import 'package:shc_stock/app/modules/reports/controllers/report_screen_controller.dart';
import 'package:shc_stock/app/modules/reports/models/report_catalog.dart';
import 'package:shc_stock/app/modules/reports/views/report_screen.dart';
import 'package:shc_stock/app/modules/reports/views/reports_catalog_view.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone coverage.
//
// Everything the app grew recently — Reports, the report shell, the bill
// screen — pumped at a real handset viewport. A RenderFlex that overflows
// throws, so these fail loudly rather than shipping a striped band no one
// looked at on a phone.
// ─────────────────────────────────────────────────────────────────────────────

/// iPhone 14 / a common Android at 1x. Narrow enough to catch a Row that only
/// ever fitted a laptop.
const _phone = Size(390, 844);

const _signedIn = SessionUser(
  id: 1,
  name: 'Chinmay Modi',
  email: 'shc@gmail.com',
  role: 'Super Admin',
  isSuperAdmin: true,
);

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = _signedIn;
}

class _StubProfile extends BillingProfileController {
  @override
  Future<void> fetch() async {
    profile.value = const BillingProfile(
      legalName: 'Secure Heat Care',
      addressLine1: 'Plot 42, GIDC Estate Phase II, Vatva',
      gstin: '24AAACS9876P1ZK',
      stateName: 'Gujarat',
      stateCode: '24',
      bankName: 'HDFC Bank Ltd, Vatva Branch',
      upiId: 'secureheatcare@hdfcbank',
      invoicePrefix: 'ST',
    );
    isLoaded.value = true;
  }
}

final _order = SalesOrder(
  id: '156',
  soNumber: 'SO-2024-00156',
  client: 'Suresh Patel Traders',
  clientBadge: 'SP',
  clientColor: Colors.orange,
  date: DateTime(2026, 7, 10),
  itemCount: 3,
  amount: 48342,
  status: SalesStatus.delivered,
  paymentStatus: PaymentStatus.paid,
  clientAddress: '18, Ring Road Industrial Area, Surat 395002, Gujarat',
  buyerGstin: '24AABCS1234F1Z5',
  destination: 'Surat',
  despatchedThrough: 'By Road',
  items: const [
    SaleDetailItem(
      product: 'Copper Pipe 15mm x 3m',
      hsn: '74111000',
      qty: 120,
      unit: 'PCS',
      rate: 288,
    ),
    SaleDetailItem(
      product: 'Brass Valve 3/4"',
      hsn: '84818090',
      qty: 24,
      unit: 'PCS',
      rate: 178,
    ),
  ],
);

/// A bill screen with the sale already in hand and no bill raised yet — the
/// state a user lands in straight from the sales list.
class _StubBill extends BillController {
  _StubBill() : super(_order);

  @override
  Future<void> load() async {
    order.value = _order;
    bill.value = null;
    options.value = profile.defaults;
    isLoading.value = false;
  }
}

class _StubReport extends ReportScreenController {
  _StubReport() : super(reportByKey('profit-loss')!);

  @override
  Future<void> load() async {
    isLoading.value = false;
    error.value = 'Backend not reachable in a test';
  }
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);
  Get.put(ExportService(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('Export chrome on a phone', () {
    testWidgets('a job toast fits the screen', (tester) async {
      await _pump(
        tester,
        const ExportOverlayHost(child: Scaffold(body: SizedBox.expand())),
      );

      // A bill PDF download is reachable on a phone, so its toast is too.
      // The job is pushed straight onto the stack rather than run: starting
      // one writes the file, and real disk I/O never completes inside a
      // widget test's fake async.
      ExportService.to.jobs.add(
        ExportJob(
          id: 1,
          filename: 'st-0248-26-27.pdf',
          format: ExportFormat.pdf,
          totalRows: 3,
          processedRows: 3,
          state: ExportJobState.ready,
          bytes: Uint8List.fromList(const [1, 2, 3]),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Export ready'), findsOneWidget);

      // The card has to sit inside the viewport, not hang off the edge.
      final card = tester.getRect(find.byType(ExportToastCard));
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(_phone.width));
    });

    testWidgets('the Downloads panel fits the screen', (tester) async {
      await _pump(
        tester,
        const ExportOverlayHost(child: Scaffold(body: SizedBox.expand())),
      );
      ExportService.to.openPanel();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Downloads'), findsOneWidget);
      final panel = tester.getRect(find.byType(DownloadsPanel));
      expect(panel.width, lessThanOrEqualTo(_phone.width));
    });
  });

  group('Export reaches every mobile list page', () {
    // A sweep rather than seven pumped pages: the point is that no list page
    // is left without a way to export, and a new one that forgets is caught.
    const layouts = {
      'products': 'lib/app/modules/products/views/mobile_products_layout.dart',
      'inventory': 'lib/app/modules/stock/views/mobile_stock_layout.dart',
      'categories':
          'lib/app/modules/categories/views/mobile_categories_layout.dart',
      'clients': 'lib/app/modules/clients/views/mobile_clients_layout.dart',
      'purchase': 'lib/app/modules/purchase/views/mobile_purchase_layout.dart',
      'sell': 'lib/app/modules/sales/views/mobile_sales_layout.dart',
      'transactions':
          'lib/app/modules/transactions/views/mobile_transactions_layout.dart',
    };

    test('each one carries the export menu', () {
      final missing = <String>[];
      layouts.forEach((name, path) {
        final source = File(path).readAsStringSync();
        if (!source.contains('ExportMenuButton')) missing.add(name);
      });
      expect(
        missing,
        isEmpty,
        reason: 'these mobile list pages cannot export: $missing',
      );
    });

    test('the web toolbar carries it too, so neither side drifts', () {
      const webLayouts = [
        'lib/app/modules/products/views/web_products_layout.dart',
        'lib/app/modules/stock/views/web_stock_layout.dart',
        'lib/app/modules/categories/views/web_categories_layout.dart',
        'lib/app/modules/clients/views/web_clients_layout.dart',
        'lib/app/modules/purchase/views/web_purchase_layout.dart',
        'lib/app/modules/sales/views/web_sales_layout.dart',
        'lib/app/modules/transactions/views/web_transactions_layout.dart',
      ];
      for (final path in webLayouts) {
        expect(
          File(path).readAsStringSync().contains('ExportMenuButton'),
          isTrue,
          reason: '$path lost its Export button',
        );
      }
    });
  });

  group('Settings on a phone', () {
    test('every web settings tab has a mobile entry point', () {
      final web = File(
        'lib/app/modules/settings/views/web_settings_layout.dart',
      ).readAsStringSync();
      final mobile = File(
        'lib/app/modules/settings/views/mobile_settings_view.dart',
      ).readAsStringSync();
      final hub = File(
        'lib/app/modules/settings/views/mobile_profile_hub_view.dart',
      ).readAsStringSync();

      // The tabs the web page offers, minus Profile — which on a phone is the
      // hub screen itself rather than a row in it.
      for (final tab in const [
        'Notifications',
        'Security',
        'Preferences',
        'Billing',
        'Appearance',
      ]) {
        expect(
          web.contains("'$tab'"),
          isTrue,
          reason: 'web settings lost the $tab tab',
        );
        expect(
          mobile.contains("'$tab'") || hub.contains("'$tab'"),
          isTrue,
          reason: '$tab is unreachable on a phone',
        );
      }
    });
  });

  group('Reports on a phone', () {
    testWidgets('the catalog lays out without overflowing', (tester) async {
      await _pump(tester, const ReportsCatalogView());

      expect(tester.takeException(), isNull);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('Profit & Loss'), findsOneWidget);
      // One card per row on a handset, not the 3-up grid.
      expect(find.text('Balance Sheet'), findsOneWidget);
    });

    testWidgets('a report screen lays out without overflowing', (tester) async {
      Get.put<ReportScreenController>(_StubReport());
      await _pump(tester, const ReportScreenView());

      expect(tester.takeException(), isNull);
      expect(find.text('Profit & Loss'), findsWidgets);
    });
  });

  group('Billing on a phone', () {
    testWidgets('the bill screen lays out without overflowing', (tester) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());

      expect(tester.takeException(), isNull);
    });

    testWidgets('the side panel and its actions are reachable', (tester) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());
      expect(tester.takeException(), isNull);

      // The panel stacks under the paper on a phone; scroll to it.
      await tester.dragUntilVisible(
        find.text('What appears on the bill'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      expect(find.text('Bill status'), findsOneWidget);
      expect(find.text('Send to client'), findsOneWidget);
      expect(find.text('Trail'), findsOneWidget);
    });

    testWidgets('all three formats are offered, not just the A4 invoice', (
      tester,
    ) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());

      // The switcher drops to its own row on a handset rather than being cut
      // with the rest of the wide toolbar.
      for (final format in BillFormat.values) {
        expect(
          find.text(format.label),
          findsOneWidget,
          reason: '${format.label} is unreachable on a phone',
        );
      }
    });

    testWidgets('tapping a format swaps the document on a phone', (
      tester,
    ) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());
      expect(find.text('BUYER (BILL TO)'), findsOneWidget);

      await tester.ensureVisible(find.text('Cash Memo'));
      await tester.tap(find.text('Cash Memo'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('CASH MEMO'), findsOneWidget);
      expect(find.text('BUYER (BILL TO)'), findsNothing);

      await tester.ensureVisible(find.text('Thermal 80mm'));
      await tester.tap(find.text('Thermal 80mm'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('80 mm roll width'), findsOneWidget);

      await tester.ensureVisible(find.text('GST Tax Invoice'));
      await tester.tap(find.text('GST Tax Invoice'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('BUYER (BILL TO)'), findsOneWidget);
    });

    testWidgets('the 80 mm roll fits a handset without sideways scrolling', (
      tester,
    ) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());
      Get.find<BillController>().showFormat(BillFormat.thermal);
      await tester.pump();

      expect(tester.takeException(), isNull);
      // The A4 sheet is wider than the phone and pans; the roll is not, so it
      // sits centred and every line of it is readable without a drag.
      final roll = tester.getSize(find.byType(ThermalReceipt));
      expect(roll.width, lessThan(_phone.width));
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('the panel greys the switches the format cannot render', (
      tester,
    ) async {
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await _pump(tester, const BillView());
      Get.find<BillController>().showFormat(BillFormat.cashMemo);
      await tester.pump();

      await tester.dragUntilVisible(
        find.text('What appears on the bill'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      final switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches.length, 5);
      expect(switches.where((x) => x.onChanged == null).length, 4);
    });
  });
}
