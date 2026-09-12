import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Writes a real exported PDF to disk so the logo can be looked at, not just
// asserted about. Skipped unless SHC_PDF_OUT names a directory, so it never
// runs as part of an ordinary `flutter test`.
//
//   flutter test test/pdf_sample_gen_test.dart --dart-define=SHC_PDF_OUT=...
// ─────────────────────────────────────────────────────────────────────────────
const _outDir = String.fromEnvironment('SHC_PDF_OUT');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes a sample export carrying the real logo', () async {
    if (_outDir.isEmpty) {
      markTestSkipped('set --dart-define=SHC_PDF_OUT to generate');
      return;
    }
    SharedPreferences.setMockInitialValues({});
    final bc = Get.put(BrandController(), permanent: true);

    final logoBytes = File('assets/logo.png').readAsBytesSync();
    bc.updateDraft(
      (b) => b.copyWith(
        companyName: 'Secure Heat Care',
        logoBase64: base64Encode(logoBytes),
      ),
    );
    await bc.apply();

    final table = ExportTable(
      title: 'Purchase Orders',
      scopeLine: 'All orders · September 2026',
      headers: const ['PO Number', 'Supplier', 'Amount', 'Status'],
      types: const [
        ExportCellType.text,
        ExportCellType.text,
        ExportCellType.money,
        ExportCellType.text,
      ],
      widths: const [1, 2, 1, 1],
      rows: [
        [
          ExportCell.text('PO-2024-10001'),
          ExportCell.text('Paatram Tableware LLP'),
          ExportCell.money(152000),
          ExportCell.text('Received'),
        ],
        [
          ExportCell.text('PO-2024-10002'),
          ExportCell.text('Maa Vaishnvi Enterprises'),
          ExportCell.money(31500),
          ExportCell.text('Partial'),
        ],
        [
          ExportCell.text('PO-2024-10003'),
          ExportCell.text('Maatigraam'),
          ExportCell.money(88250),
          ExportCell.text('Pending'),
        ],
      ],
    );

    final pdf = buildTablePdf(
      table,
      generatedLine: 'Secure Heat Care · Generated 08 Sep 2026 · Administrator',
      logo: brandPdfLogo,
    );

    final file = File('$_outDir/purchase-orders-with-logo.pdf')
      ..writeAsBytesSync(pdf);
    // ignore: avoid_print
    print('WROTE ${file.path} (${pdf.length} bytes)');
    expect(pdf.length, greaterThan(1000));

    Get.reset();
  });
}
