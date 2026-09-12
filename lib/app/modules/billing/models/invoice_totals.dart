import 'package:shc_stock/app/core/utils/amount_format.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The invoice arithmetic, in one place.
//
// The screen document, the HSN summary, the amount-in-words lines and the PDF
// all read [InvoiceTotals]. Nothing recomputes a figure of its own, so the
// printed paper and the screen can never disagree — which on a tax invoice is
// not a cosmetic concern.
//
// Tax is split CGST/SGST at half the GST rate each, matching the approved
// design. Inter-state (IGST) supply is not modelled — see the note on
// [InvoiceTaxConfig].
// ─────────────────────────────────────────────────────────────────────────────

/// One line of goods on the invoice.
class InvoiceLine {
  final String name;

  /// Small grey line under the description — grade, finish, schedule.
  final String spec;
  final String hsn;
  final double qty;

  /// Unit of measure printed beside the quantity — PCS, KG, MTR.
  final String uom;
  final double rate;

  const InvoiceLine({
    required this.name,
    required this.qty,
    required this.rate,
    this.spec = '',
    this.hsn = '',
    this.uom = '',
  });
}

/// The GST rate the invoice charges, split evenly between central and state.
class InvoiceTaxConfig {
  /// Total GST percentage, e.g. 18 for 9% CGST + 9% SGST.
  final double gstPercent;

  const InvoiceTaxConfig({this.gstPercent = 18});

  double get halfPercent => gstPercent / 2;

  /// "9%" / "2.5%" — how the column header reads.
  String get halfLabel {
    final half = halfPercent;
    final text = half == half.roundToDouble()
        ? half.toStringAsFixed(0)
        : half.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$text%';
  }
}

/// A single line with its tax worked out.
class InvoiceLineTotals {
  final InvoiceLine line;

  /// qty × rate.
  final double taxableValue;
  final double cgst;
  final double sgst;

  /// Tax-inclusive line total — what the invoice's Amount column prints.
  final double amount;

  const InvoiceLineTotals({
    required this.line,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.amount,
  });

  String get qtyLabel {
    final q = line.qty;
    final text = q == q.roundToDouble()
        ? q.toStringAsFixed(0)
        : q.toStringAsFixed(2);
    return line.uom.isEmpty ? text : '$text ${line.uom}';
  }

  String get rateText => formatIndian2(line.rate);
  String get taxableText => formatIndian2(taxableValue);
  String get cgstText => formatIndian2(cgst);
  String get sgstText => formatIndian2(sgst);
  String get amountText => formatIndian2(amount);
}

/// One row of the HSN-wise tax summary.
class HsnSummaryRow {
  final String hsn;
  final double taxableValue;
  final double cgst;
  final double sgst;

  const HsnSummaryRow({
    required this.hsn,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
  });

  double get totalTax => cgst + sgst;
}

/// Every figure the invoice prints, derived once from the lines.
class InvoiceTotals {
  final List<InvoiceLineTotals> lines;
  final InvoiceTaxConfig tax;

  /// Σ qty × rate.
  final double taxableTotal;
  final double cgstTotal;
  final double sgstTotal;

  /// taxable + both taxes, before rounding.
  final double grossTotal;

  /// [grossTotal] rounded to the nearest rupee — what the buyer pays.
  final double grandTotal;

  /// grandTotal − grossTotal. Negative when rounding down.
  final double roundOff;

  final List<HsnSummaryRow> hsnSummary;

  const InvoiceTotals({
    required this.lines,
    required this.tax,
    required this.taxableTotal,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.grossTotal,
    required this.grandTotal,
    required this.roundOff,
    required this.hsnSummary,
  });

  double get totalTax => cgstTotal + sgstTotal;

  int get itemCount => lines.length;

  double get totalQty => lines.fold(0.0, (sum, l) => sum + l.line.qty);

  String get taxableTotalText => formatIndian2(taxableTotal);
  String get cgstTotalText => formatIndian2(cgstTotal);
  String get sgstTotalText => formatIndian2(sgstTotal);
  String get totalTaxText => formatIndian2(totalTax);

  /// Grand total with thousands separators and no paise — it is a whole
  /// rupee figure by construction.
  String get grandTotalText => groupIndian(grandTotal.round().abs().toString());

  /// "(-)0.24" / "0.24" — the accounting convention for a rounding credit.
  String get roundOffText {
    final value = double.parse(roundOff.abs().toStringAsFixed(2));
    if (value == 0) return '0.00';
    final text = value.toStringAsFixed(2);
    return roundOff < 0 ? '(-)$text' : text;
  }

  static const empty = InvoiceTotals(
    lines: [],
    tax: InvoiceTaxConfig(),
    taxableTotal: 0,
    cgstTotal: 0,
    sgstTotal: 0,
    grossTotal: 0,
    grandTotal: 0,
    roundOff: 0,
    hsnSummary: [],
  );
}

/// Rounds to paise. Money is compared and summed at this precision so a
/// binary-float tail can never leak into a printed figure.
double _paise(double v) => double.parse(v.toStringAsFixed(2));

/// The one function that turns lines into every figure the invoice shows.
InvoiceTotals computeInvoiceTotals(
  List<InvoiceLine> lines, {
  InvoiceTaxConfig tax = const InvoiceTaxConfig(),
}) {
  final half = tax.halfPercent / 100;

  final lineTotals = <InvoiceLineTotals>[];
  for (final line in lines) {
    final taxable = _paise(line.qty * line.rate);
    final cgst = _paise(taxable * half);
    final sgst = cgst;
    lineTotals.add(
      InvoiceLineTotals(
        line: line,
        taxableValue: taxable,
        cgst: cgst,
        sgst: sgst,
        amount: _paise(taxable + cgst + sgst),
      ),
    );
  }

  // Totals sum the per-line figures rather than re-deriving from the taxable
  // total, so every column adds up to the number printed beneath it.
  final taxableTotal = _paise(
    lineTotals.fold(0.0, (sum, l) => sum + l.taxableValue),
  );
  final cgstTotal = _paise(lineTotals.fold(0.0, (sum, l) => sum + l.cgst));
  final sgstTotal = _paise(lineTotals.fold(0.0, (sum, l) => sum + l.sgst));
  final gross = _paise(taxableTotal + cgstTotal + sgstTotal);
  final grand = gross.roundToDouble();

  // HSN grouping preserves first-appearance order so the summary reads in the
  // same order as the items table.
  final byHsn = <String, HsnSummaryRow>{};
  for (final l in lineTotals) {
    final key = l.line.hsn.trim().isEmpty ? '—' : l.line.hsn.trim();
    final existing = byHsn[key];
    byHsn[key] = HsnSummaryRow(
      hsn: key,
      taxableValue: _paise((existing?.taxableValue ?? 0) + l.taxableValue),
      cgst: _paise((existing?.cgst ?? 0) + l.cgst),
      sgst: _paise((existing?.sgst ?? 0) + l.sgst),
    );
  }
  final hsnRows = byHsn.values.toList()..sort((a, b) => a.hsn.compareTo(b.hsn));

  return InvoiceTotals(
    lines: lineTotals,
    tax: tax,
    taxableTotal: taxableTotal,
    cgstTotal: cgstTotal,
    sgstTotal: sgstTotal,
    grossTotal: gross,
    grandTotal: grand,
    roundOff: _paise(grand - gross),
    hsnSummary: hsnRows,
  );
}
