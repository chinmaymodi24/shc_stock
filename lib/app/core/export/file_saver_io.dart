import 'dart:io';
import 'dart:typed_data';

import 'package:shc_stock/app/core/export/file_saver.dart';

/// Writes the export next to the user's other downloads.
///
/// No path_provider here on purpose: adding a plugin would force a full native
/// rebuild, and the platform directories below are reachable from dart:io
/// alone. Windows/macOS/Linux get the real Downloads folder; Android and iOS
/// get the app's own documents area, which is the only place a sandboxed app
/// may write without extra permissions.
Future<SavedFile> saveExportFile(
  String filename,
  Uint8List bytes,
  String mimeType,
) async {
  final directory = await _exportDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return SavedFile(path: file.path, location: directory.path);
}

Future<Directory> _exportDirectory() async {
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];

  if (home != null &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    final downloads = Directory('$home${Platform.pathSeparator}Downloads');
    if (await downloads.exists()) {
      return _ensure(
        Directory('${downloads.path}${Platform.pathSeparator}SHC Stock'),
      );
    }
  }

  // Mobile: the app's sandbox. systemTemp resolves to the app-private cache
  // directory there, which every share/open intent can read.
  return _ensure(
    Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}shc-exports',
    ),
  );
}

Future<Directory> _ensure(Directory directory) async {
  if (!await directory.exists()) await directory.create(recursive: true);
  return directory;
}
