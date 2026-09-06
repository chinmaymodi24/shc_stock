import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/writers/zip_writer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// XLSX writer — an OOXML workbook assembled by hand.
//
// An .xlsx is a ZIP of XML parts; the six below are the minimum Excel, LibreOffice
// and Google Sheets all accept. Strings go inline (t="inlineStr") rather than
// through a shared-strings table: one less part to keep in sync, and an export
// is written once and never edited, so the de-duplication would save nothing.
//
// Numeric columns are written as real number cells, so the sheet can sum a
// Price or Stock column the moment it opens.
// ─────────────────────────────────────────────────────────────────────────────
Uint8List buildXlsx(ExportTable table) {
  return buildZip([
    ZipEntry.text('[Content_Types].xml', _contentTypes),
    ZipEntry.text('_rels/.rels', _rootRels),
    ZipEntry.text('xl/workbook.xml', _workbook(table.title)),
    ZipEntry.text('xl/_rels/workbook.xml.rels', _workbookRels),
    ZipEntry.text('xl/styles.xml', _styles),
    ZipEntry.text('xl/worksheets/sheet1.xml', _sheet(table)),
  ]);
}

/// Excel column name for a zero-based index: 0 -> A, 25 -> Z, 26 -> AA.
String columnName(int index) {
  var value = index;
  final buffer = StringBuffer();
  while (true) {
    buffer.write(String.fromCharCode(65 + (value % 26)));
    value = value ~/ 26 - 1;
    if (value < 0) break;
  }
  return String.fromCharCodes(buffer.toString().codeUnits.reversed);
}

String _escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    // Control characters are illegal in XML 1.0 and would make the whole
    // workbook unreadable rather than showing one odd cell.
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _sheet(ExportTable table) {
  final buffer = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
    );

  // Column widths, scaled off the same hints the PDF table uses so both
  // formats give the same columns the same breathing room.
  buffer.write('<cols>');
  for (var i = 0; i < table.widths.length; i++) {
    final width = (table.widths[i] * 14).clamp(8.0, 60.0);
    buffer.write(
      '<col min="${i + 1}" max="${i + 1}" width="${width.toStringAsFixed(1)}" customWidth="1"/>',
    );
  }
  buffer.write('</cols><sheetData>');

  // Header row — style 1 is the bold fill defined in _styles.
  buffer.write('<row r="1">');
  for (var c = 0; c < table.headers.length; c++) {
    buffer.write(
      '<c r="${columnName(c)}1" s="1" t="inlineStr"><is><t xml:space="preserve">'
      '${_escapeXml(table.headers[c])}</t></is></c>',
    );
  }
  buffer.write('</row>');

  for (var r = 0; r < table.rows.length; r++) {
    final rowNumber = r + 2;
    buffer.write('<row r="$rowNumber">');
    final row = table.rows[r];
    for (var c = 0; c < row.length; c++) {
      final ref = '${columnName(c)}$rowNumber';
      final cell = row[c];
      if (cell.isNumeric && cell.number != null) {
        buffer.write('<c r="$ref"><v>${cell.number}</v></c>');
      } else if (cell.text.isEmpty) {
        buffer.write('<c r="$ref"/>');
      } else {
        buffer.write(
          '<c r="$ref" t="inlineStr"><is><t xml:space="preserve">'
          '${_escapeXml(cell.text)}</t></is></c>',
        );
      }
    }
    buffer.write('</row>');
  }

  buffer.write('</sheetData></worksheet>');
  return buffer.toString();
}

const _contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';

const _rootRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

const _workbookRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

/// Sheet names cannot exceed 31 characters or contain : \ / ? * [ ]
String _sheetName(String title) {
  final cleaned = title.replaceAll(RegExp(r'[:\/?*\[\]]'), ' ').trim();
  final safe = cleaned.isEmpty ? 'Sheet1' : cleaned;
  return safe.length <= 31 ? safe : safe.substring(0, 31);
}

String _workbook(String title) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="${_escapeXml(_sheetName(title))}" sheetId="1" r:id="rId1"/></sheets>'
    '</workbook>';

/// Two cell formats: 0 is the default, 1 is the bold header on a light fill.
const _styles = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
</fonts>
<fills count="3">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF5F4F0"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="2">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
