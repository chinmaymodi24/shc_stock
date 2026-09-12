import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/billing/models/amount_in_words.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';

// The three lines from the approved invoice design, so the numbers this suite
// asserts are the ones on the reference document.
const _designLines = [
  InvoiceLine(
    name: 'Copper Pipe 15mm x 3m',
    spec: 'Grade C, ISI marked',
    hsn: '74111000',
    qty: 120,
    uom: 'PCS',
    rate: 288,
  ),
  InvoiceLine(
    name: 'Brass Valve 3/4"',
    spec: 'Forged body, chrome finish',
    hsn: '84818090',
    qty: 24,
    uom: 'PCS',
    rate: 178,
  ),
  InvoiceLine(
    name: 'PVC Elbow Joint 90°',
    spec: 'Schedule 40',
    hsn: '39174090',
    qty: 60,
    uom: 'PCS',
    rate: 35.60,
  ),
];

void main() {
  group('Indian formatting', () {
    test('groups by lakh and crore, keeping both paise', () {
      expect(formatIndian2(14200000), '1,42,00,000.00');
      expect(formatIndian2(48342), '48,342.00');
      expect(formatIndian2(3110.4), '3,110.40');
      expect(formatIndian2(999), '999.00');
    });

    test('a zero thousands group keeps its separator', () {
      // The bug this replaced printed "30,00000".
      expect(formatIndian2(3000000), '30,00,000.00');
    });

    test('negatives keep the sign outside the grouping', () {
      expect(formatIndian2(-1250.5), '-1,250.50');
    });
  });

  group('amount in words', () {
    test('writes the design invoice total', () {
      expect(
        amountInWords(48342),
        'INR Forty Eight Thousand Three Hundred Forty Two Only',
      );
    });

    test('writes the design tax total with its paise', () {
      expect(
        amountInWords(7374.24),
        'INR Seven Thousand Three Hundred Seventy Four and 24 Paise Only',
      );
    });

    test('handles lakh and crore groups', () {
      expect(numberToIndianWords(100000), 'One Lakh');
      expect(numberToIndianWords(10000000), 'One Crore');
      expect(
        numberToIndianWords(12345678),
        'One Crore Twenty Three Lakh Forty Five Thousand Six Hundred Seventy '
        'Eight',
      );
      // Past a crore the largest named group keeps counting.
      expect(numberToIndianWords(1200000000), 'One Hundred Twenty Crore');
    });

    test('handles the teens and the round tens', () {
      expect(numberToIndianWords(15), 'Fifteen');
      expect(numberToIndianWords(40), 'Forty');
      expect(numberToIndianWords(90), 'Ninety');
      expect(numberToIndianWords(0), 'Zero');
    });

    test('skips empty groups rather than printing them', () {
      expect(numberToIndianWords(1000005), 'Ten Lakh Five');
    });

    test('omits paise when the amount is whole', () {
      expect(amountInWords(500), 'INR Five Hundred Only');
    });

    test('rounds a sub-paise tail up rather than truncating it', () {
      expect(
        amountInWords(1234.567),
        'INR One Thousand Two Hundred Thirty Four and 57 Paise Only',
      );
    });

    test('pads a single-digit paise figure', () {
      expect(amountInWords(10.05), 'INR Ten and 05 Paise Only');
    });
  });

  group('invoice totals', () {
    final totals = computeInvoiceTotals(_designLines);

    test('a line is taxable + CGST + SGST, all at the printed precision', () {
      final first = totals.lines.first;
      expect(first.taxableValue, 34560.00); // 120 × 288
      expect(first.cgst, 3110.40); // 9%
      expect(first.sgst, 3110.40);
      expect(first.amount, 40780.80);
    });

    test('a fractional rate keeps its paise', () {
      final third = totals.lines[2];
      expect(third.taxableValue, 2136.00); // 60 × 35.60
      expect(third.cgst, 192.24);
      expect(third.amount, 2520.48);
    });

    test('column totals match the design invoice', () {
      expect(totals.taxableTotal, 40968.00);
      expect(totals.cgstTotal, 3687.12);
      expect(totals.sgstTotal, 3687.12);
      expect(totals.grossTotal, 48342.24);
      expect(totals.grandTotal, 48342.00);
    });

    test(
      'round-off is the gap to the whole rupee, shown the accounting way',
      () {
        expect(totals.roundOff, closeTo(-0.24, 0.001));
        expect(totals.roundOffText, '(-)0.24');
      },
    );

    test('CGST equals SGST and both are half the GST rate', () {
      expect(totals.cgstTotal, totals.sgstTotal);
      expect(totals.cgstTotal, closeTo(totals.taxableTotal * 0.09, 0.01));
    });

    test('grand total is taxable plus tax, rounded to the rupee', () {
      expect(
        totals.grandTotal,
        (totals.taxableTotal + totals.totalTax).roundToDouble(),
      );
      expect(totals.grandTotalText, '48,342');
    });

    test('the HSN summary reconciles with the items table', () {
      final summed = totals.hsnSummary.fold<double>(
        0,
        (sum, r) => sum + r.taxableValue,
      );
      expect(summed, totals.taxableTotal);

      final tax = totals.hsnSummary.fold<double>(
        0,
        (sum, r) => sum + r.totalTax,
      );
      expect(tax, closeTo(totals.totalTax, 0.01));
      expect(totals.hsnSummary.length, 3);
    });

    test('lines sharing an HSN collapse into one summary row', () {
      final grouped = computeInvoiceTotals(const [
        InvoiceLine(name: 'A', hsn: '74111000', qty: 2, rate: 100),
        InvoiceLine(name: 'B', hsn: '74111000', qty: 3, rate: 100),
        InvoiceLine(name: 'C', hsn: '39174090', qty: 1, rate: 50),
      ]);
      expect(grouped.hsnSummary.length, 2);
      final copper = grouped.hsnSummary.firstWhere((r) => r.hsn == '74111000');
      expect(copper.taxableValue, 500);
    });

    test('a line with no HSN still appears in the summary', () {
      final noHsn = computeInvoiceTotals(const [
        InvoiceLine(name: 'Freight', qty: 1, rate: 100),
      ]);
      expect(noHsn.hsnSummary.single.hsn, '—');
      expect(noHsn.hsnSummary.single.taxableValue, 100);
    });

    test('a different GST rate moves both halves and the header label', () {
      final five = computeInvoiceTotals(const [
        InvoiceLine(name: 'A', qty: 10, rate: 100),
      ], tax: const InvoiceTaxConfig(gstPercent: 5));
      expect(five.cgstTotal, 25.00);
      expect(five.sgstTotal, 25.00);
      expect(five.grandTotal, 1050);
      expect(five.tax.halfLabel, '2.5%');
      expect(const InvoiceTaxConfig().halfLabel, '9%');
    });

    test('an empty invoice totals to zero rather than throwing', () {
      final none = computeInvoiceTotals(const []);
      expect(none.grandTotal, 0);
      expect(none.hsnSummary, isEmpty);
      expect(none.roundOffText, '0.00');
    });

    test('quantity and item counts come off the same lines', () {
      expect(totals.itemCount, 3);
      expect(totals.totalQty, 204);
    });
  });
}
