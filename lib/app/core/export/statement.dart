import 'package:shc_stock/app/core/utils/amount_format.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A financial statement, as data.
//
// One model behind both renderers: the on-screen paper sheet in Reports and
// the PDF that comes out of Export. That is the only way "the PDF reproduces
// the sheet as-is" can stay true as reports are added — a new row kind has to
// be taught to both, and nothing can drift because one of them was edited.
// ─────────────────────────────────────────────────────────────────────────────

enum StatementRowKind {
  /// INCOME, COST OF GOODS SOLD … — a small caps label, no amount.
  section,

  /// An ordinary indented line item.
  item,

  /// A bold total, ruled above and below.
  subtotal,

  /// A derived figure (Gross Profit) on a tinted band.
  derived,

  /// The bottom line — Net Profit, or the balance confirmation.
  result,

  /// Vertical breathing room between sections.
  spacer,

  /// Explanatory text, no amount. Used where the data behind a conventional
  /// line simply is not modelled, instead of printing a zero that reads as
  /// fact.
  note,
}

class StatementRow {
  final StatementRowKind kind;
  final String label;

  /// Null for section labels, spacers and notes.
  final double? amount;

  /// Renders in brackets, the accounting convention for a deduction.
  final bool negative;

  /// Identifies what the row is made of, so tapping it can open the
  /// transactions behind it. Null when a row has nothing to drill into.
  final String? drillKey;

  const StatementRow({
    required this.kind,
    required this.label,
    this.amount,
    this.negative = false,
    this.drillKey,
  });

  const StatementRow.section(this.label)
    : kind = StatementRowKind.section,
      amount = null,
      negative = false,
      drillKey = null;

  const StatementRow.item(
    this.label,
    double this.amount, {
    this.negative = false,
    this.drillKey,
  }) : kind = StatementRowKind.item;

  const StatementRow.subtotal(this.label, double this.amount)
    : kind = StatementRowKind.subtotal,
      negative = false,
      drillKey = null;

  const StatementRow.derived(this.label, double this.amount)
    : kind = StatementRowKind.derived,
      negative = false,
      drillKey = null;

  const StatementRow.result(this.label, double this.amount)
    : kind = StatementRowKind.result,
      negative = false,
      drillKey = null;

  const StatementRow.note(this.label)
    : kind = StatementRowKind.note,
      amount = null,
      negative = false,
      drillKey = null;

  const StatementRow.spacer()
    : kind = StatementRowKind.spacer,
      label = '',
      amount = null,
      negative = false,
      drillKey = null;

  /// Indian-grouped, without the ₹ prefix — the column head already carries
  /// the symbol. Deductions print as "(93,40,000)".
  String get amountText {
    if (amount == null) return '';
    final grouped = formatRupees(amount!.abs()).replaceFirst('₹', '');
    if (negative || amount! < 0) return '($grouped)';
    return grouped;
  }
}

/// A KPI card above the statement.
class StatementKpi {
  final String label;
  final String value;

  /// Renders in the success colour — used for Net Profit.
  final bool positive;

  const StatementKpi(this.label, this.value, {this.positive = false});
}

class StatementDoc {
  final String companyName;
  final String title;

  /// "For the period 01 Apr 2025 to 31 Mar 2026", or "As on 31 Mar 2026".
  final String periodLine;
  final List<StatementRow> rows;
  final List<StatementKpi> kpis;

  const StatementDoc({
    required this.companyName,
    required this.title,
    required this.periodLine,
    required this.rows,
    this.kpis = const [],
  });

  static const empty = StatementDoc(
    companyName: '',
    title: '',
    periodLine: '',
    rows: [],
  );

  bool get isEmpty => rows.isEmpty;
}
