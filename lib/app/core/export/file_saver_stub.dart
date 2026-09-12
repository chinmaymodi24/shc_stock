import 'dart:typed_data';

import 'package:shc_stock/app/core/export/file_saver.dart';

/// Never selected in practice — every Flutter target has either dart:io or
/// dart:html. Exists so the conditional import has a default.
Future<SavedFile> saveExportFile(
  String filename,
  Uint8List bytes,
  String mimeType,
) async =>
    throw UnsupportedError('File export is not supported on this platform.');

Future<bool> printPdfBytes(String filename, Uint8List bytes) async => false;

Future<bool> openExternalUrl(String url) async => false;
