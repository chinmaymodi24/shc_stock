// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:shc_stock/app/core/export/file_saver.dart';

/// Triggers a browser download.
///
/// A data: URL rather than a blob URL, so nothing has to be revoked later and
/// re-downloading the same file from the Downloads panel keeps working for as
/// long as the entry is listed.
Future<SavedFile> saveExportFile(
  String filename,
  Uint8List bytes,
  String mimeType,
) async {
  final url = 'data:$mimeType;base64,${base64Encode(bytes)}';
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  return const SavedFile(path: '', location: 'Downloads');
}
