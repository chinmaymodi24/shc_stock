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

/// Loads the PDF into an off-screen iframe and prints that frame, so the
/// browser's print preview shows the real document. The frame is left in the
/// DOM until the dialog closes — removing it immediately cancels the print on
/// Chrome.
Future<bool> printPdfBytes(String filename, Uint8List bytes) async {
  final url = 'data:application/pdf;base64,${base64Encode(bytes)}';
  final frame = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..src = url;
  html.document.body!.append(frame);
  await frame.onLoad.first;
  try {
    // contentWindow is typed WindowBase, which has no print(); the frame is
    // same-origin enough for the cast to hold on a data: URL.
    (frame.contentWindow as html.Window?)?.print();
    return true;
  } catch (e) {
    // Cross-origin restrictions on a data: frame in some browsers — fall back
    // to a download so the user still gets the document.
    frame.remove();
    return false;
  }
}

Future<bool> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
