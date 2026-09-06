import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/writers/csv_writer.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';
import 'package:shc_stock/app/core/export/writers/xlsx_writer.dart';
import 'package:shc_stock/app/core/export/writers/zip_writer.dart';

ExportTable _table({int rows = 3}) => ExportTable(
  title: 'Products',
  headers: const ['Product', 'Category', 'Price', 'Stock'],
  types: const [
    ExportCellType.text,
    ExportCellType.text,
    ExportCellType.money,
    ExportCellType.number,
  ],
  widths: const [3, 2, 1.4, 1],
  scopeLine: '$rows of 611 products · current filters',
  rows: [
    for (var i = 0; i < rows; i++)
      [
        ExportCell.text('Ceramic Fiber Blanket ${i + 1}, 128kg "25mm"'),
        ExportCell.text('Blanket'),
        ExportCell.money(4200 + i),
        ExportCell.number(84 + i),
      ],
  ],
);

void main() {
  group('CSV', () {
    test('quotes commas and doubles inner quotes', () {
      final csv = utf8.decode(buildCsv(_table(rows: 1)).sublist(3));
      final lines = csv.trim().split('\r\n');
      expect(lines.first, 'Product,Category,Price,Stock');
      expect(
        lines[1],
        '"Ceramic Fiber Blanket 1, 128kg ""25mm""",Blanket,4200,84',
      );
    });

    test('starts with a UTF-8 BOM so Excel reads ₹ correctly', () {
      final bytes = buildCsv(_table());
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('writes raw numbers, not grouped rupee text', () {
      final csv = utf8.decode(buildCsv(_table(rows: 1)).sublist(3));
      expect(csv.contains('₹'), isFalse);
    });
  });

  group('ZIP container', () {
    test('carries the local header signature and the entry name', () {
      final bytes = buildZip([ZipEntry.text('hello.txt', 'hi')]);
      expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
      expect(latin1.decode(bytes).contains('hello.txt'), isTrue);
      // End of central directory signature closes the archive.
      expect(bytes.sublist(bytes.length - 22, bytes.length - 18), [
        0x50,
        0x4B,
        0x05,
        0x06,
      ]);
    });

    test('CRC32 matches the known check value', () {
      expect(Crc32.compute(utf8.encode('123456789')), 0xCBF43926);
    });
  });

  group('XLSX', () {
    test('is a zip holding every required OOXML part', () {
      final bytes = buildXlsx(_table());
      final text = latin1.decode(bytes);
      for (final part in const [
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
      ]) {
        expect(text.contains(part), isTrue, reason: 'missing $part');
      }
    });

    test('numeric cells stay numeric and text is XML-escaped', () {
      final text = latin1.decode(buildXlsx(_table(rows: 1)));
      expect(text.contains('<v>4200</v>'), isTrue);
      expect(text.contains('&quot;25mm&quot;'), isTrue);
    });

    test('column names roll over past Z', () {
      expect(columnName(0), 'A');
      expect(columnName(25), 'Z');
      expect(columnName(26), 'AA');
      expect(columnName(27), 'AB');
    });
  });

  group('PDF', () {
    test('is a well-formed single-page document for a short table', () {
      final bytes = buildTablePdf(_table(), generatedLine: 'Generated · Test');
      final text = latin1.decode(bytes);
      expect(text.startsWith('%PDF-1.4'), isTrue);
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      expect(text.contains('/Type /Catalog'), isTrue);
      expect(text.contains('Page 1 of 1'), isTrue);
    });

    test('paginates a long table and numbers every page', () {
      final bytes = buildTablePdf(
        _table(rows: 200),
        generatedLine: 'Generated · Test',
      );
      final text = latin1.decode(bytes);
      final pageCount = RegExp(r'/Type /Page[^s]').allMatches(text).length;
      expect(pageCount, greaterThan(1));
      expect(text.contains('Page $pageCount of $pageCount'), isTrue);
    });

    test('substitutes the rupee sign, which base-14 fonts cannot draw', () {
      final text = latin1.decode(
        buildTablePdf(_table(rows: 1), generatedLine: 'x'),
      );
      expect(text.contains('Rs.4,200'), isTrue);
    });

    test('landscape is wider than portrait', () {
      final landscape = latin1.decode(
        buildTablePdf(_table(), generatedLine: 'x'),
      );
      final portrait = latin1.decode(
        buildTablePdf(
          _table(),
          layout: PdfPageLayout.portrait,
          generatedLine: 'x',
        ),
      );
      expect(landscape.contains('/MediaBox [0 0 841.89 595.28]'), isTrue);
      expect(portrait.contains('/MediaBox [0 0 595.28 841.89]'), isTrue);
    });
  });
}
