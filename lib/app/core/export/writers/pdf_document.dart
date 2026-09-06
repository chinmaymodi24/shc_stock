import 'dart:convert';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// Minimal PDF 1.4 writer.
//
// Enough of the format to lay out a table or a statement: pages, the two
// base-14 Helvetica faces, text, filled rectangles and rules. Base-14 fonts
// need no embedding, which is what keeps this dependency-free — the trade-off
// is that they carry no ₹ glyph, so [PdfText.sanitize] prints "Rs." instead.
// Everything else (screen, CSV, Excel) keeps the real symbol.
//
// The layout API works in top-left coordinates because that is how the rest of
// the app thinks; the writer flips to PDF's bottom-left origin on the way out.
// ─────────────────────────────────────────────────────────────────────────────

/// A4, in PostScript points.
const double kA4Width = 595.28;
const double kA4Height = 841.89;

class PdfColor {
  final double r;
  final double g;
  final double b;
  const PdfColor(this.r, this.g, this.b);

  factory PdfColor.hex(int value) => PdfColor(
    ((value >> 16) & 0xFF) / 255,
    ((value >> 8) & 0xFF) / 255,
    (value & 0xFF) / 255,
  );

  String get _ops => '${_fmt(r)} ${_fmt(g)} ${_fmt(b)}';

  static const black = PdfColor(0, 0, 0);
}

String _fmt(double value) {
  final rounded = double.parse(value.toStringAsFixed(3));
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded.toString();
}

class PdfPage {
  final double width;
  final double height;
  final StringBuffer _ops = StringBuffer();

  PdfPage(this.width, this.height);

  /// Draws [value] with its baseline at [y] measured from the top of the page.
  void text(
    String value,
    double x,
    double y, {
    double size = 10,
    bool bold = false,
    PdfColor color = PdfColor.black,
  }) {
    if (value.isEmpty) return;
    final escaped = _escape(PdfText.sanitize(value));
    _ops
      ..write('BT ')
      ..write('${color._ops} rg ')
      ..write('/${bold ? 'F2' : 'F1'} ${_fmt(size)} Tf ')
      ..write('${_fmt(x)} ${_fmt(height - y)} Td ')
      ..write('($escaped) Tj ET\n');
  }

  /// Same as [text] but right-aligned so its last glyph lands on [right].
  void textRight(
    String value,
    double right,
    double y, {
    double size = 10,
    bool bold = false,
    PdfColor color = PdfColor.black,
  }) {
    final w = PdfText.width(value, size, bold: bold);
    text(value, right - w, y, size: size, bold: bold, color: color);
  }

  /// Centres [value] on [centerX].
  void textCenter(
    String value,
    double centerX,
    double y, {
    double size = 10,
    bool bold = false,
    PdfColor color = PdfColor.black,
  }) {
    final w = PdfText.width(value, size, bold: bold);
    text(value, centerX - w / 2, y, size: size, bold: bold, color: color);
  }

  void rect(double x, double y, double w, double h, PdfColor color) {
    _ops.write(
      '${color._ops} rg ${_fmt(x)} ${_fmt(height - y - h)} '
      '${_fmt(w)} ${_fmt(h)} re f\n',
    );
  }

  void line(
    double x1,
    double y1,
    double x2,
    double y2, {
    PdfColor color = PdfColor.black,
    double strokeWidth = 0.5,
  }) {
    _ops.write(
      '${color._ops} RG ${_fmt(strokeWidth)} w '
      '${_fmt(x1)} ${_fmt(height - y1)} m ${_fmt(x2)} ${_fmt(height - y2)} l S\n',
    );
  }

  static String _escape(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}

class PdfDocument {
  final List<PdfPage> pages = [];
  final String title;

  PdfDocument({this.title = 'Export'});

  PdfPage addPage({double width = kA4Width, double height = kA4Height}) {
    final page = PdfPage(width, height);
    pages.add(page);
    return page;
  }

  /// Serialises the document, building the cross-reference table as it goes.
  Uint8List save() {
    // 1 catalog, 2 page tree, 3/4 the two fonts, then a pair (page, content)
    // per page.
    final objects = <String>[];
    final pageIds = <int>[];
    for (var i = 0; i < pages.length; i++) {
      pageIds.add(5 + i * 2);
    }

    objects.add('<< /Type /Catalog /Pages 2 0 R >>');
    objects.add(
      '<< /Type /Pages /Count ${pages.length} '
      '/Kids [${pageIds.map((id) => '$id 0 R').join(' ')}] >>',
    );
    objects.add(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
      '/Encoding /WinAnsiEncoding >>',
    );
    objects.add(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
      '/Encoding /WinAnsiEncoding >>',
    );

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final contentId = pageIds[i] + 1;
      objects.add(
        '<< /Type /Page /Parent 2 0 R '
        '/MediaBox [0 0 ${_fmt(page.width)} ${_fmt(page.height)}] '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
        '/Contents $contentId 0 R >>',
      );
      final stream = page._ops.toString();
      objects.add(
        '<< /Length ${latin1.encode(stream).length} >>\n'
        'stream\n$stream\nendstream',
      );
    }

    final buffer = BytesBuilder();
    void write(String value) => buffer.add(latin1.encode(value));

    write('%PDF-1.4\n');
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(buffer.length);
      write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }

    final xrefOffset = buffer.length;
    write('xref\n0 ${objects.length + 1}\n');
    write('0000000000 65535 f \n');
    for (final offset in offsets) {
      write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefOffset\n%%EOF\n',
    );

    return buffer.toBytes();
  }
}

// ── Text metrics ────────────────────────────────────────────────────────────
/// Helvetica / Helvetica-Bold advance widths, so tables can be measured,
/// right-aligned and truncated properly instead of guessed at.
class PdfText {
  PdfText._();

  /// Widths for ASCII 32..126, in 1/1000 em (from the base-14 AFM metrics).
  static const List<int> _regular = [
    278,
    278,
    355,
    556,
    556,
    889,
    667,
    191,
    333,
    333,
    389,
    584,
    278,
    333,
    278,
    278,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    278,
    278,
    584,
    584,
    584,
    556,
    1015,
    667,
    667,
    722,
    722,
    667,
    611,
    778,
    722,
    278,
    500,
    667,
    556,
    833,
    722,
    778,
    667,
    778,
    722,
    667,
    611,
    722,
    667,
    944,
    667,
    667,
    611,
    278,
    278,
    278,
    469,
    556,
    333,
    556,
    556,
    500,
    556,
    556,
    278,
    556,
    556,
    222,
    222,
    500,
    222,
    833,
    556,
    556,
    556,
    556,
    333,
    500,
    278,
    556,
    500,
    722,
    500,
    500,
    500,
    334,
    260,
    334,
    584,
  ];

  static const List<int> _bold = [
    278,
    333,
    474,
    556,
    556,
    889,
    722,
    238,
    333,
    333,
    389,
    584,
    278,
    333,
    278,
    278,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    556,
    333,
    333,
    584,
    584,
    584,
    611,
    975,
    722,
    722,
    722,
    722,
    667,
    611,
    778,
    722,
    278,
    556,
    722,
    611,
    833,
    722,
    778,
    667,
    778,
    722,
    667,
    611,
    722,
    667,
    944,
    667,
    667,
    611,
    333,
    278,
    333,
    584,
    556,
    333,
    556,
    611,
    556,
    611,
    556,
    333,
    611,
    611,
    278,
    278,
    556,
    278,
    889,
    611,
    611,
    611,
    611,
    389,
    556,
    333,
    611,
    556,
    778,
    556,
    556,
    500,
    389,
    280,
    389,
    584,
  ];

  /// Replaces glyphs the base-14 fonts cannot draw. The rupee sign is the one
  /// that matters here — left as-is it renders as a blank or a stray letter.
  static String sanitize(String value) {
    final withRupee = value.replaceAll('₹', 'Rs.');
    final buffer = StringBuffer();
    for (final rune in withRupee.runes) {
      // WinAnsiEncoding covers Latin-1; anything past it has no glyph.
      buffer.write(rune <= 0xFF ? String.fromCharCode(rune) : '?');
    }
    return buffer.toString();
  }

  static double width(String value, double size, {bool bold = false}) {
    final table = bold ? _bold : _regular;
    var total = 0;
    for (final code in sanitize(value).codeUnits) {
      // Accented Latin-1 letters share the advance of a lowercase 'n' closely
      // enough for column layout; only ASCII has an exact entry.
      total += (code >= 32 && code <= 126) ? table[code - 32] : table[78];
    }
    return total * size / 1000;
  }

  /// Cuts [value] down to [maxWidth], ending in an ellipsis when it had to.
  static String truncate(
    String value,
    double maxWidth,
    double size, {
    bool bold = false,
  }) {
    if (width(value, size, bold: bold) <= maxWidth) return value;
    const ellipsis = '...';
    final ellipsisWidth = width(ellipsis, size, bold: bold);
    var result = value;
    while (result.isNotEmpty &&
        width(result, size, bold: bold) + ellipsisWidth > maxWidth) {
      result = result.substring(0, result.length - 1);
    }
    return '$result$ellipsis';
  }

  /// Greedy word wrap to [maxWidth], for statement line items that run long.
  static List<String> wrap(
    String value,
    double maxWidth,
    double size, {
    bool bold = false,
  }) {
    final words = value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (width(candidate, size, bold: bold) <= maxWidth || current.isEmpty) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines.isEmpty ? [''] : lines;
  }
}
