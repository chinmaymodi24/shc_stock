import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_cash_memo_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_invoice_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_thermal_writer.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// GST used to be a flat 9% CGST + 9% SGST everywhere. A buyer in another state
// must be charged IGST, and each product carries its own rate.

const _seller = BillingProfile(
  legalName: 'Secure Heat Care',
  gstin: '24AAACS9876P1ZK',
  stateName: 'Gujarat',
  stateCode: '24',
);

SalesOrder _sale({required bool inter, List<SaleDetailItem>? items}) =>
    SalesOrder(
      id: '1',
      soNumber: 'SO/0001/26-27',
      client: 'Buyer',
      clientBadge: 'BU',
      clientColor: Colors.orange,
      date: DateTime(2026, 10, 10),
      itemCount: 2,
      amount: 0,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.pending,
      interState: inter,
      items:
          items ??
          const [
            SaleDetailItem(product: 'Blanket', hsn: '6806', qty: 10, rate: 100),
            SaleDetailItem(
              product: 'Mortar',
              hsn: '3816',
              qty: 2,
              rate: 500,
              taxPercent: 5,
            ),
          ],
    );

void main() {
  group('the party state', () {
    test('comes from the GSTIN first', () {
      expect(stateCodeOfGstin('27ABCDE1234F1Z5'), '27');
      expect(stateCodeOfGstin('99XYZ'), isNull);
      expect(
        partyStateCode(gstin: '29AAAAA0000A1Z5', texts: ['Gujarat']),
        '29',
      );
    });

    test('else from a state named in the text boxes', () {
      expect(stateCodeOfText('Ahmedabad (Gujarat)'), '24');
      expect(stateCodeOfText('Kolkata, West Bengal'), '19');
      expect(stateCodeOfText('Mumbai, Maharashtra 400001'), '27');
      expect(stateCodeOfText('24-Gujarat'), '24');
      expect(stateCodeOfText('Orissa'), '21', reason: 'old spelling');
      expect(stateCodeOfText('Rajkot'), isNull, reason: 'a city alone');
      expect(partyStateCode(texts: ['', 'Rajkot', 'Gujarat']), '24');
    });

    test('IGST only when both states are known and differ', () {
      expect(isInterState('24', '27'), isTrue);
      expect(isInterState('24', '24'), isFalse);
      expect(isInterState(null, '27'), isFalse, reason: 'seller unknown');
      expect(isInterState('24', null), isFalse, reason: 'party unknown');
    });

    test('the seller state comes from the billing profile', () {
      expect(_seller.sellerStateCode, '24');
      expect(
        const BillingProfile(stateName: 'Maharashtra').sellerStateCode,
        '27',
      );
      expect(BillingProfile.empty.sellerStateCode, isNull);
    });
  });

  group('computeGst', () {
    const lines = [GstLine(1000, 18), GstLine(1000, 5)];

    test('within the state: half each as CGST and SGST, per line rate', () {
      final g = computeGst(lines, interState: false);
      expect(g.cgst, 90 + 25);
      expect(g.sgst, 90 + 25);
      expect(g.igst, 0);
      expect(g.total, 2000 + 230);
      expect(g.uniformRate, isNull);
      expect(g.cgstLabel, 'CGST', reason: 'mixed rates: no single %');
    });

    test('to another state: the whole rate as IGST', () {
      final g = computeGst(lines, interState: true);
      expect(g.igst, 180 + 50);
      expect(g.cgst, 0);
      expect(g.sgst, 0);
    });

    test('one rate prints its percentage', () {
      final g = computeGst(const [GstLine(500, 18)], interState: false);
      expect(g.cgstLabel, 'CGST (9%)');
      expect(g.sgstLabel, 'SGST (9%)');
      expect(
        computeGst(const [GstLine(500, 12)], interState: true).igstLabel,
        'IGST (12%)',
      );
    });
  });

  group('orders', () {
    test('a sale taxes each line at its own rate', () {
      final s = _sale(inter: false);
      // 10 x 100 at 18% + 2 x 500 at 5%
      expect(s.cgst, 90 + 25);
      expect(s.sgst, 90 + 25);
      expect(s.igst, 0);
    });

    test('an inter-state sale carries IGST', () {
      final s = _sale(inter: true);
      expect(s.igst, 230);
      expect(s.cgst + s.sgst, 0);
    });

    test('the line rate round-trips through JSON', () {
      final json = _sale(inter: true).toCreateJson();
      expect(json['interState'], isTrue);
      expect((json['items'] as List).last['taxPercent'], 5);
      final back = SaleDetailItem.fromJson(
        Map<String, dynamic>.from((json['items'] as List).last as Map),
      );
      expect(back.taxPercent, 5);
      expect(
        SaleDetailItem.fromJson(const {'qty': 1, 'rate': 1}).taxPercent,
        18,
        reason: 'an older line without a rate is 18%',
      );
    });
  });

  group('invoice totals', () {
    InvoiceTotals totals({required bool inter}) => computeInvoiceTotals(const [
      InvoiceLine(name: 'A', hsn: '6806', qty: 10, rate: 100),
      InvoiceLine(name: 'B', hsn: '6806', qty: 2, rate: 500, taxPercent: 5),
    ], tax: InvoiceTaxConfig(interState: inter));

    test('IGST in full on an inter-state bill', () {
      final t = totals(inter: true);
      expect(t.igstTotal, 230);
      expect(t.cgstTotal + t.sgstTotal, 0);
      expect(t.grandTotal, 2230);
      expect(t.interState, isTrue);
    });

    test('one HSN at two rates gives two summary rows', () {
      final t = totals(inter: false);
      expect(t.hsnSummary.length, 2);
      expect(t.hsnSummary.map((r) => r.halfRateText), ['2.5%', '9%']);
      expect(t.cgstHeader, 'CGST', reason: 'mixed rates');
    });

    test('a single-rate bill keeps its "CGST 9%" headers', () {
      final t = computeInvoiceTotals(const [
        InvoiceLine(name: 'A', qty: 1, rate: 100),
      ]);
      expect(t.cgstHeader, 'CGST 9%');
      expect(t.igstHeader, 'IGST 18%');
      expect(t.gstHeader, 'GST 18%');
    });
  });

  group('bill PDFs on an inter-state sale', () {
    final order = _sale(inter: true);
    final t = computeInvoiceTotals([
      for (final i in order.items)
        InvoiceLine(
          name: i.product,
          hsn: i.hsn,
          qty: i.qty,
          rate: i.rate,
          taxPercent: i.taxPercent,
        ),
    ], tax: const InvoiceTaxConfig(interState: true));

    test('the tax invoice prints IGST, not CGST / SGST', () {
      final pdf = latin1.decode(
        buildInvoicePdf(
          profile: _seller,
          sellerName: 'Secure Heat Care',
          order: order,
          totals: t,
          options: const BillOptions(),
          generatedLine: 'Generated',
        ),
      );
      expect(pdf.contains('IGST'), isTrue);
      expect(pdf.contains('Integrated Tax'), isTrue);
      expect(pdf.contains('CGST'), isFalse);
      expect(pdf.contains('Central Tax'), isFalse);
    });

    test('the thermal roll prints IGST', () {
      final pdf = latin1.decode(
        buildThermalPdf(
          profile: _seller,
          sellerName: 'Secure Heat Care',
          order: order,
          totals: t,
          options: const BillOptions(),
          invoiceNo: 'ST/0001/26-27',
          invoiceDate: DateTime(2026, 10, 10),
          generatedLine: 'Generated',
        ),
      );
      expect(pdf.contains('IGST'), isTrue);
      expect(pdf.contains('CGST'), isFalse);
    });

    test('the cash memo builds', () {
      final bytes = buildCashMemoPdf(
        profile: _seller,
        sellerName: 'Secure Heat Care',
        order: order,
        totals: t,
        options: const BillOptions(),
        invoiceNo: 'ST/0001/26-27',
        invoiceDate: DateTime(2026, 10, 10),
        generatedLine: 'Generated',
        accent: const PdfColor(1, 0.5, 0),
      );
      expect(latin1.decode(bytes).startsWith('%PDF'), isTrue);
    });
  });
}
