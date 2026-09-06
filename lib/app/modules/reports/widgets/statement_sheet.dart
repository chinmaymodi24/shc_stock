import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The statement, on paper.
//
// A centred white sheet on the page's grey ground, so a Profit & Loss reads
// the way it will print. The PDF writer renders the same [StatementDoc] with
// the same bands and rules — this widget and
// `writers/pdf_statement_writer.dart` are two views of one document.
// ─────────────────────────────────────────────────────────────────────────────
class StatementSheet extends StatelessWidget {
  final StatementDoc doc;

  /// `Generated <date, time> · <user>`, printed in the sheet footer.
  final String generatedLine;

  const StatementSheet({
    super.key,
    required this.doc,
    required this.generatedLine,
  });

  static const double maxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(colors),
              const SizedBox(height: 14),
              _columnHeads(colors),
              const SizedBox(height: 6),
              for (final row in doc.rows) _row(context, colors, row),
              const SizedBox(height: 18),
              Divider(height: 1, color: colors.divider),
              const SizedBox(height: 10),
              _footer(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppThemeColors colors) => Column(
    children: [
      Text(
        doc.companyName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      const SizedBox(height: 3),
      Text(
        doc.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      const SizedBox(height: 2),
      Text(
        doc.periodLine,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
      ),
      const SizedBox(height: 12),
      Container(height: 2, color: colors.textPrimary),
    ],
  );

  Widget _columnHeads(AppThemeColors colors) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.05 * 10,
      color: colors.textHint,
      fontFamily: 'Poppins',
    );
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text('PARTICULARS', style: style)),
          Text('AMOUNT (₹)', style: style),
        ],
      ),
    );
  }

  Widget _footer(AppThemeColors colors) {
    final style = TextStyle(
      fontSize: 10.5,
      color: colors.textHint,
      fontFamily: 'Poppins',
    );
    return Row(
      children: [
        Expanded(child: Text(generatedLine, style: style)),
        Text('Page 1 of 1', style: style),
      ],
    );
  }

  // ── Rows ──────────────────────────────────────────────────────────────────
  Widget _row(BuildContext context, AppThemeColors colors, StatementRow row) {
    switch (row.kind) {
      case StatementRowKind.spacer:
        return const SizedBox(height: 14);

      case StatementRowKind.section:
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(
            row.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04 * 11,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        );

      case StatementRowKind.note:
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 0, 10),
          child: Text(
            row.label,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        );

      case StatementRowKind.item:
        final drillRoute = _routeFor(row.drillKey);
        final line = Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Text(
                  row.amountText,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        );
        if (drillRoute == null) return line;
        // Line items drill through to the transactions they are made of.
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.toNamed(drillRoute),
            child: Tooltip(
              message: 'Open the entries behind this figure',
              child: line,
            ),
          ),
        );

      case StatementRowKind.subtotal:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border),
              bottom: BorderSide(color: colors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                row.amountText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );

      case StatementRowKind.derived:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colors.background.computeLuminance() > 0.5
                ? const Color(0xFFFAF9F7)
                : colors.inputFill,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                row.amountText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );

      case StatementRowKind.result:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.success,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                row.amountText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.success,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Where a line item's drill-through lands.
  static String? _routeFor(String? drillKey) => switch (drillKey) {
    'sales' => AppRoutes.sales,
    'purchase' => AppRoutes.purchase,
    'inventory' => AppRoutes.stock,
    _ => null,
  };
}
