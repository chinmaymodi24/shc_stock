import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/bill_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/views/bill_view.dart';
import 'package:shc_stock/app/modules/billing/widgets/cash_memo.dart';
import 'package:shc_stock/app/modules/billing/widgets/thermal_receipt.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_cash_memo_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_thermal_writer.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The cash memo and the 80 mm roll, pushed at the edges.
//
// The ordinary happy path lives in billing_test.dart. What is here is the set
// of inputs that quietly produce a *wrong* document rather than an error: an
// order too long for one sheet, a name too long for the paper, an empty sale,
// a rate that is not a whole percent.
// ─────────────────────────────────────────────────────────────────────────────

const _profile = BillingProfile(
  legalName: 'Secure Heat Care',
  addressLine1: 'Plot 42, GIDC Estate Phase II, Vatva',
  addressLine2: 'Ahmedabad 382445, Gujarat',
  gstin: '24AAACS9876P1ZK',
  stateName: 'Gujarat',
  stateCode: '24',
  phone: '+91 98250 41122',
  email: 'accounts@secureheatcare.in',
  bankName: 'HDFC Bank Ltd, Vatva Branch',
  upiId: 'secureheatcare@hdfcbank',
  invoicePrefix: 'ST',
);

SalesOrder _orderOf({
  String client = 'Suresh Patel Traders',
  String address = '18, Ring Road Industrial Area, Surat 395002, Gujarat',
  int items = 3,
}) => SalesOrder(
  id: '156',
  soNumber: 'SO-2024-00156',
  client: client,
  clientBadge: 'SP',
  clientColor: Colors.orange,
  date: DateTime(2026, 7, 10),
  itemCount: items,
  amount: 48342,
  status: SalesStatus.delivered,
  paymentStatus: PaymentStatus.paid,
  clientAddress: address,
  modifiedBy: 'Chinmay Modi',
);

InvoiceTotals _totalsOf(int count, {double gstPercent = 18}) =>
    computeInvoiceTotals([
      for (var i = 0; i < count; i++)
        InvoiceLine(
          name: 'Line item ${i + 1}',
          spec: 'Grade C, ISI marked',
          hsn: '7411100${i % 3}',
          qty: 12,
          uom: 'PCS',
          rate: 288,
        ),
    ], tax: InvoiceTaxConfig(gstPercent: gstPercent));

// ─────────────────────────────────────────────────────────────────────────────
// The invariant every writer here has to hold: nothing is placed outside the
// page. A PDF happily accepts a negative coordinate and simply draws the run
// where no one can see it, so "the string is in the file" proves nothing —
// this is what catches a sheet that silently ran out of room.
// ─────────────────────────────────────────────────────────────────────────────
final _tdPattern = RegExp(r'(-?[\d.]+) (-?[\d.]+) Td');
final _boxPattern = RegExp(r'/MediaBox \[0 0 ([\d.]+) ([\d.]+)\]');

/// Every page's [width, height], in order.
List<List<double>> _pageBoxes(String pdf) => [
  for (final m in _boxPattern.allMatches(pdf))
    [double.parse(m.group(1)!), double.parse(m.group(2)!)],
];

/// Text placements that fall outside the page they are drawn on, as
/// "x,y" strings so a failure names the offender.
List<String> _offPage(String pdf) {
  final boxes = _pageBoxes(pdf);
  // Content streams follow the page objects in the same order, so the n-th
  // stream belongs to the n-th page.
  final streams = pdf.split('stream\n').skip(1).toList();
  final bad = <String>[];
  for (var i = 0; i < streams.length && i < boxes.length; i++) {
    final w = boxes[i][0];
    final h = boxes[i][1];
    for (final m in _tdPattern.allMatches(streams[i])) {
      final x = double.parse(m.group(1)!);
      final y = double.parse(m.group(2)!);
      // A baseline sitting exactly on 0 is legal; below it is not.
      if (y < 0 || y > h || x < -1 || x > w)
        bad.add('${m.group(0)} on page $i');
    }
  }
  return bad;
}

String _memo({
  InvoiceTotals? totals,
  SalesOrder? order,
  BillOptions options = const BillOptions(),
  BillingProfile profile = _profile,
  String invoiceNo = 'ST/0248/26-27',
}) => latin1.decode(
  buildCashMemoPdf(
    profile: profile,
    sellerName: profile.legalName,
    order: order ?? _orderOf(),
    totals: totals ?? _totalsOf(3),
    options: options,
    invoiceNo: invoiceNo,
    invoiceDate: DateTime(2026, 7, 10),
    generatedLine: 'Generated 10 Jul 2026 - Admin',
    accent: const PdfColor(1, 0.5, 0),
  ),
);

String _roll({
  InvoiceTotals? totals,
  SalesOrder? order,
  BillOptions options = const BillOptions(),
  BillingProfile profile = _profile,
  String invoiceNo = 'ST/0248/26-27',
}) => latin1.decode(
  buildThermalPdf(
    profile: profile,
    sellerName: profile.legalName,
    order: order ?? _orderOf(),
    totals: totals ?? _totalsOf(3),
    options: options,
    invoiceNo: invoiceNo,
    invoiceDate: DateTime(2026, 7, 10),
    generatedLine: 'Generated 10 Jul 2026 - Admin',
  ),
);

Widget _host(Widget child) => GetMaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

// A run of text with no spaces in it — the case greedy word wrap cannot break.
const _unbreakable =
    'COPPERPIPESEAMLESSHEAVYDUTYGRADECISIMARKEDFIFTEENMILLIMETREBYTHREEMETRE';

const _longName =
    'Shree Krishna Industrial Fabrication And Heat Insulation Traders '
    'Private Limited, Ahmedabad Branch';

void main() {
  group('cash memo PDF · size of the order', () {
    test('an empty sale is still a valid, honest memo', () {
      final pdf = _memo(totals: _totalsOf(0));
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(pdf.trimRight().endsWith('%%EOF'), isTrue);
      expect(pdf.contains('Rs.0'), isTrue);
      expect(pdf.contains('Rupees Zero Only'), isTrue);
      expect(_offPage(pdf), isEmpty);
    });

    test('a single line fits one sheet', () {
      final pdf = _memo(totals: _totalsOf(1));
      expect(_pageBoxes(pdf).length, 1);
      expect(_offPage(pdf), isEmpty);
    });

    test('an order too long for one sheet paginates instead of vanishing', () {
      final pdf = _memo(totals: _totalsOf(40));
      expect(_pageBoxes(pdf).length, greaterThan(1));
      // Every sheet is still A5 — the memo does not silently grow a page.
      for (final box in _pageBoxes(pdf)) {
        expect(box, [419.53, 595.28]);
      }
      // The last line is on the paper, not below it.
      expect(pdf.contains('Line item 40'), isTrue);
      expect(_offPage(pdf), isEmpty);
    });

    test('the totals and the signature land on the final sheet, once', () {
      final pdf = _memo(totals: _totalsOf(40));
      expect(RegExp('Grand Total').allMatches(pdf).length, 1);
      expect(RegExp('IN WORDS').allMatches(pdf).length, 1);
      expect(RegExp('Signature').allMatches(pdf).length, 1);
    });

    test('a continued sheet says so and repeats the column heads', () {
      final pdf = _memo(totals: _totalsOf(40));
      expect(pdf.contains(r'CASH MEMO \(continued\)'), isTrue);
      expect(RegExp('Particulars').allMatches(pdf).length, greaterThan(1));
    });
  });

  group('cash memo PDF · size of the content', () {
    test('an overlong seller and buyer are trimmed, not run off the sheet', () {
      final pdf = _memo(
        profile: _profile.copyWith(legalName: _longName),
        order: _orderOf(client: _longName, address: '$_longName, $_longName'),
      );
      expect(_offPage(pdf), isEmpty);
      // Trimmed rather than dropped: the caption is still identifiable.
      expect(pdf.contains('Shree Krishna Industrial'), isTrue);
      expect(pdf.contains('CASH MEMO'), isTrue);
    });

    test('an overlong document number keeps its label on the sheet', () {
      final pdf = _memo(invoiceNo: 'ST/${'0' * 90}/26-27');
      expect(_offPage(pdf), isEmpty);
      expect(pdf.contains('Date'), isTrue);
    });

    test('an unbreakable item name is truncated to the column', () {
      final pdf = _memo(
        totals: computeInvoiceTotals(const [
          InvoiceLine(name: _unbreakable, hsn: '74111000', qty: 1, rate: 10),
        ], tax: _profile.tax),
      );
      expect(_offPage(pdf), isEmpty);
      expect(pdf.contains('...'), isTrue);
    });

    test('a crore-scale total still fits its column', () {
      final pdf = _memo(
        totals: computeInvoiceTotals(const [
          InvoiceLine(name: 'Bulk consignment', qty: 100000, rate: 9999),
        ], tax: _profile.tax),
      );
      expect(_offPage(pdf), isEmpty);
      expect(pdf.contains('Rs.1,17,98,82,000'), isTrue);
    });

    test('an empty profile prints a memo rather than throwing', () {
      final pdf = _memo(profile: BillingProfile.empty);
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(_offPage(pdf), isEmpty);
    });
  });

  group('cash memo PDF · the tax rate', () {
    test('a whole rate reads whole, a fractional one keeps its fraction', () {
      expect(
        _memo(totals: _totalsOf(2, gstPercent: 5)).contains('GST 5%'),
        isTrue,
      );
      expect(
        _memo(totals: _totalsOf(2, gstPercent: 12.5)).contains('GST 12.5%'),
        isTrue,
      );
      expect(
        _memo(totals: _totalsOf(2, gstPercent: 0)).contains('GST 0%'),
        isTrue,
      );
    });

    test('a zero-rated memo owes exactly its goods', () {
      final totals = _totalsOf(2, gstPercent: 0);
      expect(totals.totalTax, 0);
      expect(
        _memo(totals: totals).contains('Rs.${totals.grandTotalText}'),
        isTrue,
      );
    });
  });

  group('thermal PDF · the roll', () {
    test('an empty sale still prints a receipt', () {
      final pdf = _roll(totals: _totalsOf(0));
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(pdf.contains('Rs.0'), isTrue);
      expect(_offPage(pdf), isEmpty);
    });

    test('an ordinary order is one continuous strip', () {
      for (final count in [0, 1, 3, 40, 100]) {
        final boxes = _pageBoxes(_roll(totals: _totalsOf(count)));
        expect(boxes.length, 1, reason: '$count lines split the roll');
        expect(boxes.single[0], 226.77);
      }
    });

    test('the strip grows with the order', () {
      final short = _pageBoxes(_roll(totals: _totalsOf(3))).single[1];
      final long = _pageBoxes(_roll(totals: _totalsOf(40))).single[1];
      expect(long, greaterThan(short));
    });

    test('no page ever exceeds what a PDF can express', () {
      for (final count in [0, 1, 3, 40, 600, 2000]) {
        final pdf = _roll(totals: _totalsOf(count));
        for (final box in _pageBoxes(pdf)) {
          expect(box[0], 226.77);
          // PDF caps a page edge at 14400 units; past that the file is
          // invalid and no reader will open it.
          expect(
            box[1],
            lessThanOrEqualTo(14400),
            reason: '$count lines overran the maximum PDF page height',
          );
        }
        expect(
          _offPage(pdf),
          isEmpty,
          reason: '$count lines drew off the roll',
        );
      }
    });

    test('an order past that limit splits rather than losing lines', () {
      final pdf = _roll(totals: _totalsOf(600));
      expect(_pageBoxes(pdf).length, greaterThan(1));
      // Both ends of the order survive the split, and so does the total.
      expect(pdf.contains('(Line item 1)'), isTrue);
      expect(pdf.contains('Line item 600'), isTrue);
      expect(pdf.contains('Rs.'), isTrue);
    });

    test('an unbreakable item name is trimmed to the paper', () {
      final pdf = _roll(
        totals: computeInvoiceTotals(const [
          InvoiceLine(name: _unbreakable, hsn: '74111000', qty: 1, rate: 10),
        ], tax: _profile.tax),
      );
      expect(_offPage(pdf), isEmpty);
    });

    test('an overlong party and bill number are trimmed to the paper', () {
      final pdf = _roll(
        order: _orderOf(client: _longName),
        invoiceNo: 'ST/${'0' * 90}/26-27',
      );
      expect(_offPage(pdf), isEmpty);
      expect(pdf.contains('Bill No'), isTrue);
      expect(pdf.contains('Party'), isTrue);
    });

    test('a fractional rate halves correctly on the roll', () {
      final pdf = _roll(totals: _totalsOf(2, gstPercent: 5));
      expect(pdf.contains('CGST 2.5%'), isTrue);
      expect(pdf.contains('SGST 2.5%'), isTrue);
    });

    test('an empty profile prints a receipt rather than throwing', () {
      final pdf = _roll(profile: BillingProfile.empty);
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(_offPage(pdf), isEmpty);
    });
  });

  group('the documents on screen · extremes', () {
    Future<void> pump(WidgetTester tester, Widget child, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(child));
      await tester.pump();
    }

    testWidgets('an empty sale renders both documents', (tester) async {
      await pump(
        tester,
        CashMemo(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _orderOf(items: 0),
          totals: _totalsOf(0),
          options: const BillOptions(),
          invoiceNo: 'ST/0248/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        ),
        const Size(1000, 1600),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('₹0'), findsOneWidget);

      await pump(
        tester,
        ThermalReceipt(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _orderOf(items: 0),
          totals: _totalsOf(0),
          options: const BillOptions(),
          invoiceNo: 'ST/0248/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        ),
        const Size(700, 1600),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('overlong names do not overflow the memo', (tester) async {
      await pump(
        tester,
        CashMemo(
          profile: _profile.copyWith(legalName: _longName),
          sellerName: _longName,
          order: _orderOf(client: _longName, address: '$_longName, $_longName'),
          totals: computeInvoiceTotals(const [
            InvoiceLine(name: _unbreakable, hsn: '74111000', qty: 1, rate: 10),
          ], tax: _profile.tax),
          options: const BillOptions(),
          invoiceNo: 'ST/${'0' * 60}/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        ),
        const Size(1200, 2400),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('overlong names do not overflow the roll', (tester) async {
      await pump(
        tester,
        ThermalReceipt(
          profile: _profile.copyWith(
            legalName: _longName,
            gstin: '2' * 60,
            addressLine1: _longName,
          ),
          sellerName: _longName,
          order: _orderOf(client: _longName),
          totals: computeInvoiceTotals([
            InvoiceLine(name: _unbreakable, hsn: '7' * 40, qty: 1, rate: 10),
          ], tax: _profile.tax),
          options: const BillOptions(),
          invoiceNo: 'ST/${'0' * 60}/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        ),
        const Size(700, 3000),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a forty-line order renders both documents', (tester) async {
      await pump(
        tester,
        CashMemo(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _orderOf(items: 40),
          totals: _totalsOf(40),
          options: const BillOptions(),
          invoiceNo: 'ST/0248/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        ),
        const Size(1200, 4000),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Line item 40'), findsOneWidget);
    });
  });

  group('the bill screen · every format at every width', () {
    Future<void> pump(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put(ThemeController(), permanent: true);
      Get.put<SessionController>(_StubSession(), permanent: true);
      Get.put(ExportService(), permanent: true);
      Get.put<BillingProfileController>(_StubProfile());
      await BillingProfileController.to.fetch();
      Get.put<BillController>(_StubBill());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: [AppThemeColors.light]),
          home: const BillView(),
        ),
      );
      await tester.pump();
    }

    setUp(Get.reset);
    tearDown(Get.reset);

    for (final size in const [
      Size(360, 800), // small handset
      Size(414, 900), // large handset
      Size(768, 1024), // tablet, just past the toolbar's wide threshold
      Size(1180, 900), // the width the side panel appears at
      Size(1600, 1000), // desktop
    ]) {
      testWidgets('lays out at ${size.width.toInt()}px in all three formats', (
        tester,
      ) async {
        await pump(tester, size);
        expect(tester.takeException(), isNull);

        for (final format in BillFormat.values) {
          Get.find<BillController>().showFormat(format);
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${format.label} overflowed at ${size.width}px',
          );
        }
      });
    }

    testWidgets('the switcher moves the document and the file name', (
      tester,
    ) async {
      await pump(tester, const Size(1600, 1000));
      final controller = Get.find<BillController>();

      expect(controller.fileName.endsWith('-memo.pdf'), isFalse);
      expect(find.text('BUYER (BILL TO)'), findsOneWidget);

      await tester.ensureVisible(find.text('Cash Memo'));
      await tester.tap(find.text('Cash Memo'));
      await tester.pump();
      expect(find.text('CASH MEMO'), findsOneWidget);
      expect(find.text('BUYER (BILL TO)'), findsNothing);
      expect(controller.fileName.endsWith('-memo.pdf'), isTrue);

      await tester.ensureVisible(find.text('Thermal 80mm'));
      await tester.tap(find.text('Thermal 80mm'));
      await tester.pump();
      expect(find.textContaining('80 mm roll width'), findsOneWidget);
      expect(controller.fileName.endsWith('-thermal.pdf'), isTrue);

      await tester.ensureVisible(find.text('GST Tax Invoice'));
      await tester.tap(find.text('GST Tax Invoice'));
      await tester.pump();
      expect(find.text('BUYER (BILL TO)'), findsOneWidget);
      expect(controller.fileName.endsWith('.pdf'), isTrue);
      expect(controller.fileName.contains('-memo'), isFalse);
    });

    testWidgets('every format builds bytes that are a real PDF', (
      tester,
    ) async {
      await pump(tester, const Size(1600, 1000));
      for (final format in BillFormat.values) {
        Get.find<BillController>().showFormat(format);
        final bytes = Get.find<BillController>().buildPdf();
        final pdf = latin1.decode(bytes);
        expect(pdf.startsWith('%PDF-1.4'), isTrue, reason: format.label);
        expect(_offPage(pdf), isEmpty, reason: format.label);
      }
    });

    testWidgets('a switch that the format ignores is not offered', (
      tester,
    ) async {
      await pump(tester, const Size(1600, 1000));

      // On the tax invoice all five are live.
      var switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches.length, 5);
      expect(switches.where((s) => s.onChanged == null), isEmpty);

      Get.find<BillController>().showFormat(BillFormat.cashMemo);
      await tester.pump();
      switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches.where((s) => s.onChanged == null).length, 4);
      expect(find.textContaining('do not reach the cash memo'), findsOneWidget);

      Get.find<BillController>().showFormat(BillFormat.thermal);
      await tester.pump();
      switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches.where((s) => s.onChanged == null).length, 3);
    });
  });
}

// ── Stubs ────────────────────────────────────────────────────────────────────
class _StubSession extends SessionController {
  @override
  Future<void> restore() async {}
}

class _StubProfile extends BillingProfileController {
  @override
  Future<void> fetch() async {
    profile.value = _profile;
    isLoaded.value = true;
  }
}

class _StubBill extends BillController {
  _StubBill() : super(_stubOrder);

  @override
  Future<void> load() async {
    order.value = _stubOrder;
    bill.value = null;
    options.value = profile.defaults;
    isLoading.value = false;
  }
}

final _stubOrder = SalesOrder(
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
  invoiceNo: 'ST/0248/26-27',
  invoiceDate: DateTime(2026, 7, 10),
  modifiedBy: 'Chinmay Modi',
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
    SaleDetailItem(
      product: 'PVC Elbow Joint 90°',
      hsn: '39174090',
      qty: 60,
      unit: 'PCS',
      rate: 35.60,
    ),
  ],
);
