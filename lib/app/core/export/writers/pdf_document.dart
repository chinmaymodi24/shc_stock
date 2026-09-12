import 'dart:ui' as ui;
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

/// A5, in PostScript points — the cash memo's sheet. Half an A4, which is the
/// size a counter memo book is printed at.
const double kA5Width = 419.53;
const double kA5Height = 595.28;

/// The printable width of an 80 mm thermal roll, in PostScript points.
///
/// The roll is 80 mm but every ESC/POS head leaves an unprintable margin, so
/// the industry prints 72 mm of it. The page is the full 80 mm; the writer
/// keeps its content inside the 72.
const double kThermalRollWidth = 226.77; // 80 mm
const double kThermalPrintWidth = 204.09; // 72 mm

/// The largest page edge PDF can express — 200 inches. A page beyond it is
/// out of spec and readers reject the file, so anything that sizes a page to
/// its content (the thermal roll) has to split before it gets here.
const double kPdfMaxPageExtent = 14400;

class PdfColor {
  final double r;
  final double g;
  final double b;
  const PdfColor(this.r, this.g, this.b);

  /// A Flutter [Color] as a PDF colour, so an exported report can be painted
  /// from the same brand the screens use rather than a parallel set of hexes.
  factory PdfColor.of(ui.Color color) => PdfColor(
    ((color.toARGB32() >> 16) & 0xFF) / 255,
    ((color.toARGB32() >> 8) & 0xFF) / 255,
    (color.toARGB32() & 0xFF) / 255,
  );

  factory PdfColor.hex(int value) => PdfColor(
    ((value >> 16) & 0xFF) / 255,
    ((value >> 8) & 0xFF) / 255,
    (value & 0xFF) / 255,
  );

  String get _ops => '${_fmt(r)} ${_fmt(g)} ${_fmt(b)}';

  static const black = PdfColor(0, 0, 0);
  static const white = PdfColor(1, 1, 1);
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
    bool mono = false,
    PdfColor color = PdfColor.black,
  }) {
    if (value.isEmpty) return;
    final escaped = _escape(PdfText.sanitize(value));
    _ops
      ..write('BT ')
      ..write('${color._ops} rg ')
      ..write('/${_fontRef(bold: bold, mono: mono)} ${_fmt(size)} Tf ')
      ..write('${_fmt(x)} ${_fmt(height - y)} Td ')
      ..write('($escaped) Tj ET\n');
  }

  /// Which of the four base-14 faces a run of text uses. Numerals go in
  /// Courier so invoice columns line up digit for digit.
  static String _fontRef({required bool bold, required bool mono}) {
    if (mono) return bold ? 'F4' : 'F3';
    return bold ? 'F2' : 'F1';
  }

  /// Same as [text] but right-aligned so its last glyph lands on [right].
  void textRight(
    String value,
    double right,
    double y, {
    double size = 10,
    bool bold = false,
    bool mono = false,
    PdfColor color = PdfColor.black,
  }) {
    final w = PdfText.width(value, size, bold: bold, mono: mono);
    text(value, right - w, y, size: size, bold: bold, mono: mono, color: color);
  }

  /// Centres [value] on [centerX].
  void textCenter(
    String value,
    double centerX,
    double y, {
    double size = 10,
    bool bold = false,
    bool mono = false,
    PdfColor color = PdfColor.black,
  }) {
    final w = PdfText.width(value, size, bold: bold, mono: mono);
    text(
      value,
      centerX - w / 2,
      y,
      size: size,
      bold: bold,
      mono: mono,
      color: color,
    );
  }

  void rect(double x, double y, double w, double h, PdfColor color) {
    _ops.write(
      '${color._ops} rg ${_fmt(x)} ${_fmt(height - y - h)} '
      '${_fmt(w)} ${_fmt(h)} re f\n',
    );
  }

  /// Draws one of the document's registered images into the box at [x],[y]
  /// (measured from the top, like everything else here). [index] is the
  /// position in `PdfDocument.images` — 0 for a document carrying only a logo.
  ///
  /// PDF paints an image into the unit square, so the CTM has to scale it up
  /// to the box first — hence the `w 0 0 h x y cm` before the `Do`. The
  /// q/Q pair keeps that transform from leaking into everything drawn after.
  void image(int index, double x, double y, double w, double h) {
    _ops.write(
      'q ${_fmt(w)} 0 0 ${_fmt(h)} ${_fmt(x)} ${_fmt(height - y - h)} cm '
      '/Im$index Do Q\n',
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

/// A decoded bitmap ready to embed: 8-bit RGB, no alpha, row-major.
///
/// Decoding happens outside the writer (see `decodeLogoForPdf`) because
/// Flutter's image codecs are async and the writers are not. Alpha is
/// composited onto white there too — PDF would need a separate soft-mask
/// object to honour transparency, and a logo on a white report page looks
/// identical either way.
class PdfImage {
  final int width;
  final int height;

  /// `width * height * 3` bytes.
  final Uint8List rgb;

  const PdfImage({
    required this.width,
    required this.height,
    required this.rgb,
  });
}

/// One serialised PDF object: a dictionary, and for streams the bytes that
/// follow it. Binary payloads are kept out of the dictionary string because
/// image data is not latin1-safe.
class _PdfObject {
  final String dict;
  final Uint8List? stream;
  const _PdfObject(this.dict, [this.stream]);
}

class PdfDocument {
  final List<PdfPage> pages = [];
  final String title;

  /// Images the pages may draw, in the order [PdfPage.image] indexes them:
  /// `/Im0`, `/Im1`, … Every page shares the same set, so a logo repeated on
  /// forty pages is stored once. An invoice registers two — the brand mark and
  /// the authorised signature.
  final List<PdfImage> images;

  PdfDocument({this.title = 'Export', List<PdfImage>? images})
    : images = images ?? const [];

  PdfPage addPage({double width = kA4Width, double height = kA4Height}) {
    final page = PdfPage(width, height);
    pages.add(page);
    return page;
  }

  /// Serialises the document, building the cross-reference table as it goes.
  Uint8List save() {
    // 1 catalog, 2 page tree, 3–6 the four base-14 faces (Helvetica pair for
    // prose, Courier pair for figures), then one XObject per registered image,
    // then a pair (page, content) per page.
    final objects = <_PdfObject>[];
    const firstImageId = 7;
    final firstPageId = firstImageId + images.length;
    final pageIds = <int>[];
    for (var i = 0; i < pages.length; i++) {
      pageIds.add(firstPageId + i * 2);
    }

    objects.add(const _PdfObject('<< /Type /Catalog /Pages 2 0 R >>'));
    objects.add(
      _PdfObject(
        '<< /Type /Pages /Count ${pages.length} '
        '/Kids [${pageIds.map((id) => '$id 0 R').join(' ')}] >>',
      ),
    );
    objects.add(
      const _PdfObject(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );
    objects.add(
      const _PdfObject(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );
    objects.add(
      const _PdfObject(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Courier '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );
    objects.add(
      const _PdfObject(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );

    for (final img in images) {
      // Stored uncompressed: these are small, and a Flate filter would mean
      // shipping a deflate implementation for the sake of a few dozen KB.
      objects.add(
        _PdfObject(
          '<< /Type /XObject /Subtype /Image '
          '/Width ${img.width} /Height ${img.height} '
          '/ColorSpace /DeviceRGB /BitsPerComponent 8 '
          '/Length ${img.rgb.length} >>',
          img.rgb,
        ),
      );
    }

    final xobject = images.isEmpty
        ? ''
        : '/XObject << ${[for (var i = 0; i < images.length; i++) '/Im$i ${firstImageId + i} 0 R'].join(' ')} >> ';

    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final contentId = pageIds[i] + 1;
      objects.add(
        _PdfObject(
          '<< /Type /Page /Parent 2 0 R '
          '/MediaBox [0 0 ${_fmt(page.width)} ${_fmt(page.height)}] '
          '/Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R /F4 6 0 R >> '
          '$xobject>> '
          '/Contents $contentId 0 R >>',
        ),
      );
      final stream = latin1.encode(page._ops.toString());
      objects.add(_PdfObject('<< /Length ${stream.length} >>', stream));
    }

    final buffer = BytesBuilder();
    void write(String value) => buffer.add(latin1.encode(value));

    write('%PDF-1.4\n');
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(buffer.length);
      final obj = objects[i];
      write('${i + 1} 0 obj\n${obj.dict}\n');
      if (obj.stream != null) {
        write('stream\n');
        buffer.add(obj.stream!);
        write('\nendstream\n');
      }
      write('endobj\n');
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
  /// WinAnsiEncoding's 0x80–0x9F block, which Latin-1 leaves undefined. These
  /// are the characters ordinary UI copy actually uses — an em dash in a
  /// placeholder, curly quotes out of a text field — and without the mapping
  /// each one printed as "?".
  static const Map<int, int> _winAnsiExtras = {
    0x20AC: 0x80, // €
    0x201A: 0x82, // ‚
    0x0192: 0x83, // ƒ
    0x201E: 0x84, // „
    0x2026: 0x85, // …
    0x2020: 0x86, // †
    0x2021: 0x87, // ‡
    0x02C6: 0x88, // ˆ
    0x2030: 0x89, // ‰
    0x0160: 0x8A, // Š
    0x2039: 0x8B, // ‹
    0x0152: 0x8C, // Œ
    0x017D: 0x8E, // Ž
    0x2018: 0x91, // ‘
    0x2019: 0x92, // ’
    0x201C: 0x93, // “
    0x201D: 0x94, // ”
    0x2022: 0x95, // •
    0x2013: 0x96, // –
    0x2014: 0x97, // —
    0x02DC: 0x98, // ˜
    0x2122: 0x99, // ™
    0x0161: 0x9A, // š
    0x203A: 0x9B, // ›
    0x0153: 0x9C, // œ
    0x017E: 0x9E, // ž
    0x0178: 0x9F, // Ÿ
  };

  static String sanitize(String value) {
    final withRupee = value.replaceAll('₹', 'Rs.');
    final buffer = StringBuffer();
    for (final rune in withRupee.runes) {
      final mapped = _winAnsiExtras[rune];
      if (mapped != null) {
        buffer.writeCharCode(mapped);
      } else {
        // The rest of WinAnsiEncoding matches Latin-1; past that there is no
        // glyph to draw.
        buffer.write(rune <= 0xFF ? String.fromCharCode(rune) : '?');
      }
    }
    return buffer.toString();
  }

  /// Courier's advance width — the same for every glyph, which is the point.
  static const int _monoAdvance = 600;

  static double width(
    String value,
    double size, {
    bool bold = false,
    bool mono = false,
  }) {
    if (mono) return sanitize(value).length * _monoAdvance * size / 1000;
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
    bool mono = false,
  }) {
    if (width(value, size, bold: bold, mono: mono) <= maxWidth) return value;
    const ellipsis = '...';
    final ellipsisWidth = width(ellipsis, size, bold: bold, mono: mono);
    var result = value;
    while (result.isNotEmpty &&
        width(result, size, bold: bold, mono: mono) + ellipsisWidth >
            maxWidth) {
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
    bool mono = false,
  }) {
    final words = value.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (width(candidate, size, bold: bold, mono: mono) <= maxWidth ||
          current.isEmpty) {
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
