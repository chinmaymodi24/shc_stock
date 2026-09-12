import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The brand logo in exported PDFs.
//
// A buyer's mark has to reach the reports, and every way an upload can be
// wrong has to leave the export working: no logo, an SVG the engine can't
// decode, a corrupt blob, a transparent PNG. None of those may throw — the
// report just falls back to the short-code plate.
// ─────────────────────────────────────────────────────────────────────────────

/// A real 1×1 fully-transparent PNG — the same fixture
/// product_image_widgets_test.dart decodes, so it is known to be genuine.
/// Transparent on purpose: it exercises the composite-onto-white path.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

ExportTable _table() => ExportTable(
  title: 'Purchase Orders',
  scopeLine: 'All orders',
  headers: const ['PO Number'],
  types: const [ExportCellType.text],
  widths: const [1],
  rows: [
    [ExportCell.text('PO-2201')],
  ],
);

/// A 2×1 PNG painted on the spot: opaque red, then fully transparent.
/// Built rather than inlined so the alpha under test is not an assumption.
Future<String> _paintPng({int width = 2, int height = 1}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return base64Encode(
    data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

/// Where the image XObject would be, if one was written.
bool _hasImageObject(Uint8List pdf) =>
    latin1.decode(pdf, allowInvalid: true).contains('/Subtype /Image');

void main() {
  // ui.instantiateImageCodec needs the engine; these are plain unit tests, so
  // the binding has to be stood up by hand.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetPdfLogoCache);
  tearDown(resetPdfLogoCache);

  group('decodeLogoForPdf', () {
    test('decodes a real PNG to RGB at 3 bytes per pixel', () async {
      final image = await decodeLogoForPdf(base64Encode(_png));

      expect(image, isNotNull);
      expect(image!.width, 1);
      expect(image.height, 1);
      expect(image.rgb.length, image.width * image.height * 3);
    });

    test('composites transparency onto white, not onto black', () async {
      // Painted rather than pasted, so the alpha is known: an opaque red
      // pixel beside a fully transparent one.
      final png = await _paintPng();
      final image = (await decodeLogoForPdf(png))!;

      expect(image.width, 2);
      expect(image.rgb.sublist(0, 3), [255, 0, 0], reason: 'opaque red kept');
      // Dropping the alpha byte would leave this one black — a dark square
      // stamped on a white report.
      expect(image.rgb.sublist(3, 6), [
        255,
        255,
        255,
      ], reason: 'transparent composites to white');
    });

    test('a missing logo is simply null', () async {
      expect(await decodeLogoForPdf(null), isNull);
      expect(await decodeLogoForPdf(''), isNull);
    });

    test('an SVG upload degrades to null instead of throwing', () async {
      final svg = base64Encode(
        utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"/>'),
      );
      expect(await decodeLogoForPdf(svg), isNull);
    });

    test('corrupt bytes and invalid base64 degrade to null', () async {
      expect(await decodeLogoForPdf('not-base64!!'), isNull);
      expect(await decodeLogoForPdf(base64Encode([1, 2, 3, 4])), isNull);
    });

    test('a small logo is left alone, not blown up to the cap', () async {
      final image = await decodeLogoForPdf(base64Encode(_png));
      // Upscaling a 1px mark to 256px would add ~196KB of nothing to every
      // exported report.
      expect(image!.width, 1);
      expect(image.height, 1);
    });

    test('an oversized logo is capped, keeping its aspect ratio', () async {
      final wide = await _paintPng(width: 900, height: 300);
      final image = (await decodeLogoForPdf(wide))!;

      expect(image.width, kMaxLogoEdge);
      expect(image.height, closeTo(kMaxLogoEdge / 3, 1));
      expect(image.rgb.length, image.width * image.height * 3);
    });

    test('a tall logo is capped on its own long edge', () async {
      final tall = await _paintPng(width: 300, height: 900);
      final image = (await decodeLogoForPdf(tall))!;

      expect(image.height, kMaxLogoEdge);
      expect(image.width, closeTo(kMaxLogoEdge / 3, 1));
    });
  });

  group('the cache the writers read', () {
    test('warms, and re-warms when the logo changes', () async {
      expect(brandPdfLogo, isNull);

      await warmPdfLogoCache(base64Encode(_png));
      expect(brandPdfLogo, isNotNull);

      // Removing the logo must clear it, not leave the old one behind.
      await warmPdfLogoCache(null);
      expect(brandPdfLogo, isNull);
    });
  });

  // The chain a buyer actually walks: upload a logo in Appearance, press
  // Apply, then export. Each link is unit-tested above; this is the one that
  // proves they are joined up.
  group('upload -> apply -> export', () {
    tearDown(Get.reset);

    test('an applied logo reaches an exported PDF', () async {
      SharedPreferences.setMockInitialValues({});
      final bc = Get.put(BrandController(), permanent: true);

      // No logo yet: the export carries no image.
      expect(brandPdfLogo, isNull);
      expect(
        _hasImageObject(
          buildTablePdf(_table(), generatedLine: 'g', logo: brandPdfLogo),
        ),
        isFalse,
      );

      // Upload, then Apply — which is what warms the decode cache.
      bc.updateDraft((b) => b.copyWith(logoBase64: base64Encode(_png)));
      await bc.apply();

      expect(brandPdfLogo, isNotNull, reason: 'Apply must decode the logo');
      final pdf = buildTablePdf(
        _table(),
        generatedLine: 'g',
        logo: brandPdfLogo,
      );
      expect(_hasImageObject(pdf), isTrue);
      expect(latin1.decode(pdf, allowInvalid: true), contains('/Im0 Do'));
    });

    test('removing the logo takes it back out of the PDF', () async {
      SharedPreferences.setMockInitialValues({});
      final bc = Get.put(BrandController(), permanent: true);

      bc.updateDraft((b) => b.copyWith(logoBase64: base64Encode(_png)));
      await bc.apply();
      expect(brandPdfLogo, isNotNull);

      bc.updateDraft((b) => b.copyWith(clearLogo: true));
      await bc.apply();

      expect(brandPdfLogo, isNull, reason: 'a stale logo must not linger');
      expect(
        _hasImageObject(
          buildTablePdf(_table(), generatedLine: 'g', logo: brandPdfLogo),
        ),
        isFalse,
      );
    });
  });

  group('buildTablePdf', () {
    test('embeds the logo as an image XObject when there is one', () async {
      final logo = await decodeLogoForPdf(base64Encode(_png));
      final pdf = buildTablePdf(
        _table(),
        generatedLine: 'Generated now',
        logo: logo,
      );

      expect(_hasImageObject(pdf), isTrue);
      final text = latin1.decode(pdf, allowInvalid: true);
      expect(text, contains('/XObject << /Im0'));
      expect(text, contains('/Im0 Do'), reason: 'and actually draws it');
      expect(text, startsWith('%PDF-1.4'));
      expect(text, contains('%%EOF'));
    });

    test('without a logo it writes no image and still renders', () {
      final pdf = buildTablePdf(_table(), generatedLine: 'Generated now');

      expect(_hasImageObject(pdf), isFalse);
      final text = latin1.decode(pdf, allowInvalid: true);
      expect(text, isNot(contains('/Im0')));
      expect(text, contains('Purchase Orders'));
      expect(text, contains('%%EOF'));
    });

    test(
      'the xref offsets stay correct once binary data is in the file',
      () async {
        // A stream of raw image bytes shifts every later object; if the xref
        // table were still built from string lengths the file would be corrupt.
        final logo = await decodeLogoForPdf(base64Encode(_png));
        final pdf = buildTablePdf(
          _table(),
          generatedLine: 'Generated now',
          logo: logo,
        );
        final text = latin1.decode(pdf, allowInvalid: true);

        final startxref = RegExp(r'startxref\s+(\d+)').firstMatch(text);
        expect(startxref, isNotNull);
        final xrefAt = int.parse(startxref!.group(1)!);
        expect(
          text.substring(xrefAt, xrefAt + 4),
          'xref',
          reason: 'startxref must point at the real xref table',
        );

        // Every offset in the table must land on an "N 0 obj" header.
        final offsets = RegExp(
          r'^(\d{10}) 00000 n',
          multiLine: true,
        ).allMatches(text).map((m) => int.parse(m.group(1)!)).toList();
        expect(offsets, isNotEmpty);
        for (var i = 0; i < offsets.length; i++) {
          expect(
            text.startsWith('${i + 1} 0 obj', offsets[i]),
            isTrue,
            reason: 'object ${i + 1} is not at its declared offset',
          );
        }
      },
    );
  });
}
