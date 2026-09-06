/// The stretch of time (or the single date) a report covers.
///
/// Built here rather than in the view so the toolbar chip, the statement's
/// period line, the API query and the export filename all describe the same
/// window.
class ReportPeriod {
  final String label;
  final DateTime from;
  final DateTime to;

  /// Slug used in export filenames — "fy2025-26", "sep-2026", "q3-2026".
  final String slug;

  const ReportPeriod({
    required this.label,
    required this.from,
    required this.to,
    required this.slug,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  /// "01 Apr 2025 — 31 Mar 2026" — the read-only chip beside the selector.
  String get rangeLabel => '${formatDate(from)} — ${formatDate(to)}';

  /// The line printed under a period report's title.
  String get statementLine =>
      'For the period ${formatDate(from)} to ${formatDate(to)}';

  /// The line printed under an as-on-date report's title.
  String get asOnLine => 'As on ${formatDate(to)}';

  /// "As on 31 Mar 2026" — what the toolbar shows for a balance-sheet-style
  /// report, where a range would be meaningless.
  String get asOnLabel => 'As on ${formatDate(to)}';

  /// Indian financial year starting 1 April [startYear].
  factory ReportPeriod.financialYear(int startYear) {
    final endShort = ((startYear + 1) % 100).toString().padLeft(2, '0');
    return ReportPeriod(
      label: 'FY $startYear-$endShort',
      from: DateTime(startYear, 4, 1),
      to: DateTime(startYear + 1, 3, 31, 23, 59, 59),
      slug: 'fy$startYear-$endShort',
    );
  }

  /// The financial year containing [now].
  factory ReportPeriod.currentFinancialYear([DateTime? now]) {
    final date = now ?? DateTime.now();
    return ReportPeriod.financialYear(
      date.month >= 4 ? date.year : date.year - 1,
    );
  }

  factory ReportPeriod.thisMonth([DateTime? now]) {
    final date = now ?? DateTime.now();
    final start = DateTime(date.year, date.month, 1);
    // Day 0 of the next month is the last day of this one — no month-length
    // table, and February and leap years take care of themselves.
    final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    return ReportPeriod(
      label: 'This Month',
      from: start,
      to: end,
      slug: '${_months[date.month - 1].toLowerCase()}-${date.year}',
    );
  }

  factory ReportPeriod.thisQuarter([DateTime? now]) {
    final date = now ?? DateTime.now();
    final startMonth = ((date.month - 1) ~/ 3) * 3 + 1;
    return ReportPeriod(
      label: 'This Quarter',
      from: DateTime(date.year, startMonth, 1),
      to: DateTime(date.year, startMonth + 3, 0, 23, 59, 59),
      slug: 'q${(startMonth - 1) ~/ 3 + 1}-${date.year}',
    );
  }

  factory ReportPeriod.custom(DateTime from, DateTime to) => ReportPeriod(
    label: 'Custom range',
    from: DateTime(from.year, from.month, from.day),
    to: DateTime(to.year, to.month, to.day, 23, 59, 59),
    slug:
        '${from.year}${from.month.toString().padLeft(2, '0')}'
        '${from.day.toString().padLeft(2, '0')}-'
        '${to.year}${to.month.toString().padLeft(2, '0')}'
        '${to.day.toString().padLeft(2, '0')}',
  );

  /// The three financial years the selector offers, newest first.
  static List<ReportPeriod> recentFinancialYears([DateTime? now]) {
    final current = ReportPeriod.currentFinancialYear(now);
    final startYear = current.from.year;
    return [
      for (var i = 0; i < 3; i++) ReportPeriod.financialYear(startYear - i),
    ];
  }
}
