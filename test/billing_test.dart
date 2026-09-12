import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'dart:typed_data';

import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/widgets/cash_memo.dart';
import 'package:shc_stock/app/modules/billing/widgets/gst_tax_invoice.dart';
import 'package:shc_stock/app/modules/billing/widgets/thermal_receipt.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_cash_memo_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_invoice_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_thermal_writer.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

const _profile = BillingProfile(
  legalName: 'Secure Heat Care',
  addressLine1: 'Plot 42, GIDC Estate Phase II, Vatva',
  addressLine2: 'Ahmedabad 382445, Gujarat',
  gstin: '24AAACS9876P1ZK',
  pan: 'AABCS1234F',
  stateName: 'Gujarat',
  stateCode: '24',
  phone: '+91 98250 41122',
  email: 'accounts@secureheatcare.in',
  bankName: 'HDFC Bank Ltd, Vatva Branch',
  accountNo: '50200034567890',
  branchAndIfsc: 'Vatva · HDFC0001234',
  upiId: 'secureheatcare@hdfcbank',
  invoicePrefix: 'ST',
);

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
  pan: 'AABCS1234F',
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
    SaleDetailItem(
      product: 'PVC Elbow Joint 90°',
      hsn: '39174090',
      qty: 60,
      unit: 'PCS',
      rate: 35.60,
    ),
  ],
);

InvoiceTotals get _totals => computeInvoiceTotals([
  for (final i in _order.items)
    InvoiceLine(
      name: i.product,
      hsn: i.hsn,
      qty: i.qty,
      uom: i.unit,
      rate: i.rate,
    ),
], tax: _profile.tax);

Widget _host(Widget child) => GetMaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

Widget _invoice({BillOptions options = const BillOptions(), BillModel? bill}) =>
    GstTaxInvoice(
      profile: _profile,
      sellerName: 'Secure Heat Care',
      order: _order,
      totals: _totals,
      options: options,
      bill: bill,
      invoiceNo: 'ST/0248/26-27',
      invoiceDate: DateTime(2026, 7, 10),
    );

void main() {
  group('BillingProfile', () {
    test('round-trips through JSON', () {
      final decoded = BillingProfile.fromJson(
        jsonDecode(jsonEncode(_profile.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.gstin, '24AAACS9876P1ZK');
      expect(decoded.invoicePrefix, 'ST');
      expect(decoded.upiId, 'secureheatcare@hdfcbank');
      expect(decoded.gstPercent, 18);
    });

    test('a half-written blob degrades to defaults, not to nothing', () {
      final partial = BillingProfile.fromJson({'gstin': '24AAACS9876P1ZK'});
      expect(partial.gstin, '24AAACS9876P1ZK');
      expect(partial.invoicePrefix, 'INV');
      expect(partial.gstPercent, 18);
      expect(partial.declaration, BillingProfile.defaultDeclaration);
      expect(partial.defaults.showHsnSummary, isTrue);
    });

    test(
      'an out-of-range GST rate falls back rather than printing nonsense',
      () {
        expect(BillingProfile.fromJson({'gstPercent': 900}).gstPercent, 18);
        expect(BillingProfile.fromJson({'gstPercent': 5}).gstPercent, 5);
      },
    );

    test('the signature round-trips and can be cleared', () {
      final signed = _profile.copyWith(signatureBase64: 'QUJD');
      expect(signed.signatureBase64, 'QUJD');

      final decoded = BillingProfile.fromJson(signed.toJson());
      expect(decoded.signatureBase64, 'QUJD');

      // copyWith cannot null a field, hence the explicit flag.
      expect(signed.copyWith(clearSignature: true).signatureBase64, isNull);
      // And a plain copyWith leaves it alone.
      expect(signed.copyWith(pan: 'X').signatureBase64, 'QUJD');
    });

    test('no signature is the default', () {
      expect(_profile.signatureBase64, isNull);
      expect(BillingProfile.fromJson({}).signatureBase64, isNull);
    });

    test('a profile without a GSTIN is not configured', () {
      expect(BillingProfile.empty.isConfigured, isFalse);
      expect(_profile.isConfigured, isTrue);
    });

    test('the tax config follows the profile rate', () {
      expect(_profile.tax.halfLabel, '9%');
      expect(_profile.copyWith(gstPercent: 5).tax.halfLabel, '2.5%');
    });
  });

  group('BillModel', () {
    test('reads the API shape, including an absent IRN', () {
      final bill = BillModel.fromJson({
        'id': 7,
        'salesOrderId': 156,
        'invoiceNo': 'ST/0248/26-27',
        'issuedOn': '2026-07-10T13:10:00.000Z',
        'options': {'showHsnSummary': false},
        'eInvoice': {'irn': null, 'ackNo': null, 'ackDate': null},
        'generatedBy': 'Chinmay Modi',
        'events': [
          {
            'id': 1,
            'type': 'generated',
            'note': '',
            'actor': 'Chinmay Modi',
            'at': '2026-07-10T13:10:00.000Z',
          },
        ],
      });
      expect(bill.invoiceNo, 'ST/0248/26-27');
      expect(bill.options.showHsnSummary, isFalse);
      // Unspecified options keep their default rather than flipping off.
      expect(bill.options.showBankDetails, isTrue);
      expect(bill.eInvoice.isRegistered, isFalse);
      expect(bill.events.single.label, 'Invoice generated');
    });

    test('an IRN, when there is one, reads as registered', () {
      final bill = BillModel.fromJson({
        'id': 7,
        'salesOrderId': 156,
        'invoiceNo': 'ST/0248/26-27',
        'issuedOn': '2026-07-10T13:10:00.000Z',
        'eInvoice': {'irn': 'a5d3f8b71c9e4a26b0f45d8e19c73a6f', 'ackNo': '112'},
      });
      expect(bill.eInvoice.isRegistered, isTrue);
      expect(bill.eInvoice.ackNo, '112');
    });

    test('the summary card reads its counts and the latest bill', () {
      final summary = BillingSummary.fromJson({
        'generated': 4,
        'pending': 1,
        'irnRegistered': 0,
        'irnTotal': 4,
        'latest': {'id': 9, 'invoiceNo': 'ST/0248/26-27', 'salesOrderId': 156},
      });
      expect(summary.generated, 4);
      expect(summary.pending, 1);
      expect(summary.latestSalesOrderId, 156);
    });
  });

  group('invoice PDF', () {
    String render({BillOptions options = const BillOptions()}) => latin1.decode(
      buildInvoicePdf(
        profile: _profile,
        sellerName: 'Secure Heat Care',
        order: _order,
        totals: _totals,
        options: options,
        generatedLine: 'Generated 10 Jul 2026 · Admin',
      ),
    );

    test('is a well-formed PDF', () {
      final pdf = render();
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(pdf.trimRight().endsWith('%%EOF'), isTrue);
      expect(pdf.contains('/BaseFont /Courier'), isTrue);
    });

    test('carries the seller, the buyer and the figures', () {
      final pdf = render();
      expect(pdf.contains('Secure Heat Care'), isTrue);
      expect(pdf.contains('Suresh Patel Traders'), isTrue);
      expect(pdf.contains('24AAACS9876P1ZK'), isTrue);
      expect(pdf.contains('40,968.00'), isTrue); // taxable total
      expect(pdf.contains('3,687.12'), isTrue); // CGST total
      expect(pdf.contains('48,342'), isTrue); // grand total
    });

    test('prints the amount in words', () {
      expect(
        render().contains(
          'INR Forty Eight Thousand Three Hundred Forty Two Only',
        ),
        isTrue,
      );
    });

    test('the HSN toggle removes the summary and its words band', () {
      final on = render();
      final off = render(options: const BillOptions(showHsnSummary: false));
      expect(on.contains('Total Tax Amount'), isTrue);
      expect(off.contains('Total Tax Amount'), isFalse);
      // Parentheses delimit a PDF string literal, so they arrive escaped.
      expect(on.contains(r'Tax Amount \(in words\)'), isTrue);
      expect(off.contains(r'Tax Amount \(in words\)'), isFalse);
    });

    test('the bank toggle removes the bank block', () {
      expect(render().contains('HDFC Bank Ltd'), isTrue);
      expect(
        render(
          options: const BillOptions(showBankDetails: false),
        ).contains('HDFC Bank Ltd'),
        isFalse,
      );
    });

    test('says the invoice is unregistered rather than inventing an IRN', () {
      final pdf = render();
      expect(pdf.contains('Not registered with the IRP'), isTrue);
    });

    test('the rupee sign becomes Rs. — base-14 fonts have no glyph for it', () {
      expect(render().contains('Rs. 48,342'), isTrue);
    });

    test('a signature is embedded and drawn in its own slot', () {
      // A 2x2 red square is enough — this asserts wiring, not pixels.
      final image = PdfImage(
        width: 2,
        height: 2,
        rgb: Uint8List.fromList(List.filled(2 * 2 * 3, 200)),
      );
      final pdf = latin1.decode(
        buildInvoicePdf(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _order,
          totals: _totals,
          options: const BillOptions(),
          generatedLine: 'Generated · Test',
          signature: image,
        ),
      );
      expect(pdf.contains('/Subtype /Image'), isTrue);
      // Only the signature is registered here, so it takes slot 0.
      expect(pdf.contains('/XObject << /Im0'), isTrue);
      expect(pdf.contains('/Im0 Do'), isTrue);
    });

    test('a logo and a signature each get their own slot', () {
      PdfImage box(int v) => PdfImage(
        width: 2,
        height: 2,
        rgb: Uint8List.fromList(List.filled(2 * 2 * 3, v)),
      );
      final pdf = latin1.decode(
        buildInvoicePdf(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _order,
          totals: _totals,
          options: const BillOptions(),
          generatedLine: 'Generated · Test',
          logo: box(10),
          signature: box(200),
        ),
      );
      // Logo first, signature second — and both are drawn.
      expect(pdf.contains('/Im0'), isTrue);
      expect(pdf.contains('/Im1'), isTrue);
      expect(pdf.contains('/Im1 Do'), isTrue);
      expect(RegExp(r'/Subtype /Image').allMatches(pdf).length, 2);
    });

    test('no signature leaves the signatory line blank, not broken', () {
      final pdf = render();
      expect(pdf.contains('Authorised Signatory'), isTrue);
      expect(pdf.contains('/Im1 Do'), isFalse);
    });

    test('a long invoice paginates and repeats the items header', () {
      final many = [
        for (var i = 0; i < 40; i++)
          InvoiceLine(
            name: 'Line item ${i + 1}',
            spec: 'Grade C, ISI marked',
            hsn: '7411100${i % 3}',
            qty: 10,
            uom: 'PCS',
            rate: 250 + i.toDouble(),
          ),
      ];
      final pdf = latin1.decode(
        buildInvoicePdf(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _order,
          totals: computeInvoiceTotals(many, tax: _profile.tax),
          options: const BillOptions(),
          generatedLine: 'Generated · Test',
        ),
      );
      final pages = RegExp(r'/Type /Page[^s]').allMatches(pdf).length;
      expect(pages, greaterThan(1));
      expect(pdf.contains('Page $pages of $pages'), isTrue);
      // The continuation page carries the column heads again, not orphan rows.
      expect(
        RegExp('Description of Goods').allMatches(pdf).length,
        greaterThan(1),
      );
      expect(pdf.contains(r'TAX INVOICE \(continued\)'), isTrue);
    });
  });

  group('invoice on screen', () {
    testWidgets('prints the ruled document with its figures', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(_invoice()));

      expect(find.text('T A X   I N V O I C E'), findsOneWidget);
      expect(find.text('Secure Heat Care'), findsWidgets);
      expect(find.text('BUYER (BILL TO)'), findsOneWidget);
      expect(find.text('CONSIGNEE (SHIP TO)'), findsOneWidget);
      expect(find.text('ST/0248/26-27'), findsOneWidget);
      // Column heads carry the rate from the profile.
      expect(find.text('CGST 9%'), findsOneWidget);
      expect(find.text('SGST 9%'), findsOneWidget);
      // Figures, straight off the totals engine. The line's taxable value
      // appears twice — once in the items table, once in the HSN summary.
      expect(find.text('34,560.00'), findsNWidgets(2));
      expect(find.text('40,968.00'), findsWidgets);
      expect(find.text('₹ 48,342'), findsOneWidget);
      expect(find.text('(-)0.24'), findsOneWidget);
      expect(
        find.text('INR Forty Eight Thousand Three Hundred Forty Two Only'),
        findsOneWidget,
      );
    });

    testWidgets('the HSN summary appears and disappears with its toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(_invoice()));
      expect(find.text('Total Tax Amount'), findsOneWidget);
      expect(find.text('Tax Amount (in words)'), findsOneWidget);

      await tester.pumpWidget(
        _host(_invoice(options: const BillOptions(showHsnSummary: false))),
      );
      expect(find.text('Total Tax Amount'), findsNothing);
      expect(find.text('Tax Amount (in words)'), findsNothing);
    });

    testWidgets('the bank and declaration toggles remove their blocks', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(_invoice()));
      expect(find.text("COMPANY'S BANK DETAILS"), findsOneWidget);
      expect(find.text('DECLARATION'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          _invoice(
            options: const BillOptions(
              showBankDetails: false,
              showDeclaration: false,
            ),
          ),
        ),
      );
      expect(find.text("COMPANY'S BANK DETAILS"), findsNothing);
      expect(find.text('DECLARATION'), findsNothing);
    });

    testWidgets('an unregistered invoice says so', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(_invoice()));
      expect(find.text('Not registered with the IRP'), findsOneWidget);
    });

    testWidgets('the signature prints above the signatory line', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // A 1x1 transparent PNG — enough for the widget to lay out.
      const png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
          'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

      await tester.pumpWidget(
        _host(
          GstTaxInvoice(
            profile: _profile.copyWith(signatureBase64: png),
            sellerName: 'Secure Heat Care',
            order: _order,
            totals: _totals,
            options: const BillOptions(),
            invoiceNo: 'ST/0248/26-27',
            invoiceDate: DateTime(2026, 7, 10),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('invoice-signature')), findsOneWidget);
      expect(find.text('Authorised Signatory'), findsOneWidget);
    });

    testWidgets('a broken signature degrades to blank space', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          GstTaxInvoice(
            profile: _profile.copyWith(signatureBase64: 'not base64 at all!!'),
            sellerName: 'Secure Heat Care',
            order: _order,
            totals: _totals,
            options: const BillOptions(),
            invoiceNo: 'ST/0248/26-27',
            invoiceDate: DateTime(2026, 7, 10),
          ),
        ),
      );
      // The document still renders; the signature slot is simply empty.
      expect(find.byKey(const ValueKey('invoice-signature')), findsNothing);
      expect(find.text('Authorised Signatory'), findsOneWidget);
      expect(find.text('for Secure Heat Care'), findsOneWidget);
    });

    testWidgets('the UPI QR block goes with its toggle', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(_invoice()));
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);

      await tester.pumpWidget(
        _host(_invoice(options: const BillOptions(showUpiQr: false))),
      );
      expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The other two formats. One bill, three layouts — the point of these tests
  // is that switching layout never moves a figure.
  // ───────────────────────────────────────────────────────────────────────────
  group('BillFormat', () {
    test('every switch reaches the tax invoice', () {
      for (final option in BillOption.values) {
        expect(BillFormat.taxInvoice.applies(option), isTrue);
      }
    });

    test('the memo and the roll only own the switches they can render', () {
      // A memo has no HSN summary, no bank block, no IRN and no QR.
      expect(BillFormat.cashMemo.applies(BillOption.declaration), isTrue);
      expect(BillFormat.cashMemo.applies(BillOption.hsnSummary), isFalse);
      expect(BillFormat.cashMemo.applies(BillOption.bankDetails), isFalse);
      expect(BillFormat.cashMemo.applies(BillOption.eInvoice), isFalse);
      // 72 mm has room for the HSN line and the returns note, nothing else.
      expect(BillFormat.thermal.applies(BillOption.hsnSummary), isTrue);
      expect(BillFormat.thermal.applies(BillOption.declaration), isTrue);
      expect(BillFormat.thermal.applies(BillOption.upiQr), isFalse);
    });

    test('each format exports to its own file name', () {
      expect(BillFormat.taxInvoice.fileSuffix, '');
      expect(BillFormat.cashMemo.fileSuffix, '-memo');
      expect(BillFormat.thermal.fileSuffix, '-thermal');
    });

    test('an option reads and writes the switch it names', () {
      const options = BillOptions();
      expect(BillOption.upiQr.read(options), isTrue);
      final off = BillOption.upiQr.write(options, false);
      expect(off.showUpiQr, isFalse);
      // And leaves the other four alone.
      expect(off.showHsnSummary, isTrue);
      expect(off.showDeclaration, isTrue);
    });
  });

  group('cash memo PDF', () {
    String render({BillOptions options = const BillOptions()}) => latin1.decode(
      buildCashMemoPdf(
        profile: _profile,
        sellerName: 'Secure Heat Care',
        order: _order,
        totals: _totals,
        options: options,
        invoiceNo: 'ST/0248/26-27',
        invoiceDate: DateTime(2026, 7, 10),
        generatedLine: 'Generated 10 Jul 2026 - Admin',
        accent: const PdfColor(1, 0.5, 0),
      ),
    );

    test('is a well-formed A5 sheet', () {
      final pdf = render();
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(pdf.trimRight().endsWith('%%EOF'), isTrue);
      expect(pdf.contains('/MediaBox [0 0 419.53 595.28]'), isTrue);
      // One sheet — a counter memo does not paginate.
      expect(RegExp(r'/Type /Page[^s]').allMatches(pdf).length, 1);
    });

    test('carries the seller, the buyer and the memo caption', () {
      final pdf = render();
      expect(pdf.contains('CASH MEMO'), isTrue);
      expect(pdf.contains('Secure Heat Care'), isTrue);
      expect(pdf.contains('Suresh Patel Traders'), isTrue);
      expect(pdf.contains('ST/0248/26-27'), isTrue);
    });

    test('owes the same money as the tax invoice', () {
      final pdf = render();
      expect(pdf.contains('40,968.00'), isTrue); // sub total
      expect(pdf.contains('7,374.24'), isTrue); // the whole GST, in one line
      expect(pdf.contains('Rs.48,342'), isTrue); // the invoice's grand total
      expect(
        pdf.contains(
          'Rupees Forty Eight Thousand Three Hundred Forty Two Only',
        ),
        isTrue,
      );
    });

    test('the declaration toggle removes the terms line', () {
      expect(
        render().contains('Goods once sold will not be taken back'),
        isTrue,
      );
      final off = render(options: const BillOptions(showDeclaration: false));
      expect(off.contains('Goods once sold will not be taken back'), isFalse);
      // The signature rule stays either way — someone still signs the memo.
      expect(off.contains('Signature'), isTrue);
    });
  });

  group('thermal PDF', () {
    String render({
      BillOptions options = const BillOptions(),
      InvoiceTotals? totals,
    }) => latin1.decode(
      buildThermalPdf(
        profile: _profile,
        sellerName: 'Secure Heat Care',
        order: _order,
        totals: totals ?? _totals,
        options: options,
        invoiceNo: 'ST/0248/26-27',
        invoiceDate: DateTime(2026, 7, 10),
        generatedLine: 'Generated 10 Jul 2026 - Admin',
      ),
    );

    double pageHeight(String pdf) => double.parse(
      RegExp(r'/MediaBox \[0 0 [\d.]+ ([\d.]+)\]').firstMatch(pdf)!.group(1)!,
    );

    test('is an 80 mm roll, not a page', () {
      final pdf = render();
      expect(pdf.startsWith('%PDF-1.4'), isTrue);
      expect(pdf.contains('/MediaBox [0 0 226.77 '), isTrue);
      expect(RegExp(r'/Type /Page[^s]').allMatches(pdf).length, 1);
    });

    test('the roll grows with the order rather than paginating', () {
      final short = pageHeight(render());
      final long = pageHeight(
        render(
          totals: computeInvoiceTotals([
            for (var i = 0; i < 20; i++)
              InvoiceLine(
                name: 'Line item ${i + 1}',
                hsn: '74111000',
                qty: 4,
                uom: 'PCS',
                rate: 120,
              ),
          ], tax: _profile.tax),
        ),
      );
      expect(long, greaterThan(short));
      expect(RegExp(r'/Type /Page[^s]').allMatches(render()).length, 1);
    });

    test('prints the same figures as the A4 sheet', () {
      final pdf = render();
      expect(pdf.contains('TAX INVOICE'), isTrue);
      expect(pdf.contains('40,968.00'), isTrue);
      expect(pdf.contains('3,687.12'), isTrue);
      expect(pdf.contains(r'\(-\)0.24'), isTrue);
      expect(pdf.contains('Rs.48,342'), isTrue);
      expect(pdf.contains('3 / 204'), isTrue); // items / units
    });

    test('the HSN toggle takes the codes off the roll', () {
      expect(render().contains('74111000'), isTrue);
      expect(
        render(
          options: const BillOptions(showHsnSummary: false),
        ).contains('74111000'),
        isFalse,
      );
    });

    test('the declaration toggle takes the returns note off the roll', () {
      expect(render().contains('Goods once sold not returnable'), isTrue);
      final off = render(options: const BillOptions(showDeclaration: false));
      expect(off.contains('Goods once sold not returnable'), isFalse);
      // The thank-you stays — it is not a term of sale.
      expect(off.contains('Thank you, visit again'), isTrue);
    });
  });

  group('cash memo on screen', () {
    Widget memo({BillOptions options = const BillOptions()}) => CashMemo(
      profile: _profile,
      sellerName: 'Secure Heat Care',
      order: _order,
      totals: _totals,
      options: options,
      invoiceNo: 'ST/0248/26-27',
      invoiceDate: DateTime(2026, 7, 10),
    );

    testWidgets('prints the counter layout on the invoice figures', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(memo()));

      expect(find.text('CASH MEMO'), findsOneWidget);
      expect(find.text('Particulars'), findsOneWidget);
      expect(find.text('ST/0248/26-27'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);
      // The same rupee figure the tax invoice prints.
      expect(find.text('₹48,342'), findsOneWidget);
      expect(find.text('GST 18%'), findsOneWidget);
      expect(
        find.text('Rupees Forty Eight Thousand Three Hundred Forty Two Only'),
        findsOneWidget,
      );
      // No tax invoice furniture on a counter memo.
      expect(find.text('CONSIGNEE (SHIP TO)'), findsNothing);
      expect(find.text('HSN/SAC'), findsNothing);
    });

    testWidgets('the declaration toggle removes the terms line', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(memo()));
      expect(find.text(CashMemo.memoTerms), findsOneWidget);

      await tester.pumpWidget(
        _host(memo(options: const BillOptions(showDeclaration: false))),
      );
      expect(find.text(CashMemo.memoTerms), findsNothing);
      expect(find.text('Signature'), findsOneWidget);
    });
  });

  group('thermal receipt on screen', () {
    Widget receipt({BillOptions options = const BillOptions()}) =>
        ThermalReceipt(
          profile: _profile,
          sellerName: 'Secure Heat Care',
          order: _order,
          totals: _totals,
          options: options,
          invoiceNo: 'ST/0248/26-27',
          invoiceDate: DateTime(2026, 7, 10),
        );

    testWidgets('is one narrow column carrying the same total', (tester) async {
      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(receipt()));

      expect(find.text('TAX INVOICE'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('₹48,342'), findsOneWidget);
      expect(find.text('CGST 9%'), findsOneWidget);
      expect(find.text('10/07/26'), findsOneWidget);
      expect(find.text('3 / 204'), findsOneWidget);
      expect(find.text('74111000'), findsOneWidget);
      expect(find.text(ThermalReceipt.returnsNote), findsOneWidget);
    });

    testWidgets('the toggles reach the roll', (tester) async {
      tester.view.physicalSize = const Size(700, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          receipt(
            options: const BillOptions(
              showHsnSummary: false,
              showDeclaration: false,
            ),
          ),
        ),
      );
      expect(find.text('74111000'), findsNothing);
      expect(find.text(ThermalReceipt.returnsNote), findsNothing);
      // The figures are not a display option.
      expect(find.text('₹48,342'), findsOneWidget);
    });
  });
}
