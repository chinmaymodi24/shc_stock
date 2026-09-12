import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart'
    as impl;

/// Where a finished export ended up, so the toast and the Downloads panel can
/// say something concrete instead of "saved".
class SavedFile {
  /// Absolute path on desktop/mobile; empty on web, where the browser owns
  /// the destination.
  final String path;

  /// Human-readable location — "Downloads" on web, the folder otherwise.
  final String location;

  const SavedFile({required this.path, required this.location});
}

/// Hands [bytes] to the platform: a browser download on web, a file in the
/// app's exports folder elsewhere.
Future<SavedFile> saveExportFile(
  String filename,
  Uint8List bytes,
  String mimeType,
) => impl.saveExportFile(filename, bytes, mimeType);

/// Hands [bytes] to the platform's print path.
///
/// On the web the PDF is loaded into a hidden frame and the browser's print
/// dialog is opened on it, so what prints is the generated document rather
/// than a screenshot of the canvas. Everywhere else there is no print API
/// without a plugin, so this returns false and the caller falls back to
/// saving the file for the user to print themselves.
Future<bool> printPdfBytes(String filename, Uint8List bytes) =>
    impl.printPdfBytes(filename, bytes);

/// Opens [url] outside the app — a wa.me link, a mailto:, a payment page.
/// Returns false where the platform offers no way to do it without a plugin;
/// callers then copy the link to the clipboard instead of failing silently.
Future<bool> openExternalUrl(String url) => impl.openExternalUrl(url);
