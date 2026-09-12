import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The paper palette.
//
// A printed invoice has no dark mode, so — unlike every other surface in this
// app — the document does NOT read from the theme. It is black on white in
// both themes and on paper, which is the whole point: what is on screen is
// what comes out of the printer. The brand accent appears only where the spec
// allows it, on the logo.
// ─────────────────────────────────────────────────────────────────────────────
class InvoicePaper {
  InvoicePaper._();

  /// A4 at 96 dpi — the tax invoice's sheet.
  static const double width = 794;

  /// A5 at 96 dpi — the cash memo's sheet, half an A4 the long way.
  static const double memoWidth = 559;

  /// An 80 mm roll at 96 dpi, and the 72 mm of it an ESC/POS head can
  /// actually reach. Content is laid out inside [thermalContentWidth] so what
  /// is on screen is what the printer can render.
  static const double thermalWidth = 302;
  static const double thermalContentWidth = 272;

  static const Color ink = Color(0xFF1A1A2E);
  static const Color muted = Color(0xFF5A5770);
  static const Color faint = Color(0xFF8A8797);
  static const Color rule = Color(0xFF1A1A2E);
  static const Color shade = Color(0xFFF5F4F0);
  static const Color paper = Colors.white;

  static const BorderSide side = BorderSide(color: rule, width: 0.7);

  /// The document's body face. Numerals use [mono] so every column of figures
  /// lines up digit for digit, the way a ledger is read.
  static String get body => brandFontFamily;
  static String get mono => fontFamilyFor('IBM Plex Mono');

  // ── Type ──────────────────────────────────────────────────────────────────
  /// Small grey cell caption — "Invoice No.", "GSTIN/UIN".
  static TextStyle caption([double size = 8.5]) => TextStyle(
    fontSize: size,
    height: 1.3,
    letterSpacing: 0.2,
    color: faint,
    fontFamily: body,
  );

  /// Ordinary body text inside a cell.
  static TextStyle text([double size = 10.5]) =>
      TextStyle(fontSize: size, height: 1.35, color: muted, fontFamily: body);

  /// The bold value beneath a caption.
  static TextStyle value([double size = 11]) => TextStyle(
    fontSize: size,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: ink,
    fontFamily: body,
  );

  /// Any figure: amounts, HSN codes, GSTINs, invoice numbers.
  static TextStyle number([
    double size = 10.5,
    FontWeight weight = FontWeight.w500,
  ]) => TextStyle(
    fontSize: size,
    height: 1.3,
    fontWeight: weight,
    color: ink,
    fontFamily: mono,
  );

  /// Section heading inside the document — "BUYER (BILL TO)".
  static TextStyle sectionCaption() => TextStyle(
    fontSize: 8,
    height: 1.3,
    letterSpacing: 0.7,
    fontWeight: FontWeight.w600,
    color: faint,
    fontFamily: body,
  );
}

/// A bordered cell of the ruled document. Borders are drawn on the right and
/// bottom only, with the enclosing [InvoiceBox] supplying the top and left —
/// so adjacent cells share one rule instead of stacking two.
class InvoiceCell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool right;
  final bool bottom;
  final Color? background;
  final double? height;
  final CrossAxisAlignment align;

  const InvoiceCell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 8, 10, 9),
    this.right = false,
    this.bottom = false,
    this.background,
    this.height,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: right ? InvoicePaper.side : BorderSide.none,
          bottom: bottom ? InvoicePaper.side : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [child],
      ),
    );
  }
}

/// The outer rule around a band of cells.
class InvoiceBox extends StatelessWidget {
  final Widget child;
  final bool bottom;

  const InvoiceBox({super.key, required this.child, this.bottom = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: InvoicePaper.side,
          right: InvoicePaper.side,
          top: InvoicePaper.side,
          bottom: bottom ? InvoicePaper.side : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}

/// A grey caption with its value beneath — the pattern the header grid and the
/// party blocks are built from.
class CaptionValue extends StatelessWidget {
  final String caption;
  final String value;
  final bool mono;

  const CaptionValue({
    super.key,
    required this.caption,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption, style: InvoicePaper.caption()),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: mono
              ? InvoicePaper.number(11, FontWeight.w600)
              : InvoicePaper.value(),
        ),
      ],
    );
  }
}

/// An inline `Label: value` line, the value in the figures face.
class LabelledValue extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const LabelledValue({
    super.key,
    required this.label,
    required this.value,
    this.mono = true,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: InvoicePaper.text(10),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: mono
                  ? InvoicePaper.number(10, FontWeight.w600)
                  : InvoicePaper.value(10),
            ),
          ],
        ),
      ),
    );
  }
}

/// The torn rule a receipt uses instead of a ruled border. Thermal paper is
/// too narrow for boxes, so the sections are separated by dashes — which is
/// also all an ESC/POS printer can draw without graphics mode.
class PaperDashedRule extends StatelessWidget {
  final double height;
  final Color color;

  const PaperDashedRule({
    super.key,
    this.height = 1,
    this.color = InvoicePaper.faint,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: CustomPaint(painter: _DashPainter(color)),
  );
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    const dash = 3.0;
    const gap = 2.5;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(end, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
