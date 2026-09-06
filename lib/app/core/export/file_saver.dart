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
