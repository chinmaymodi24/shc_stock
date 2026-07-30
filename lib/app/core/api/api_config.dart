import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Central place for the backend base URL.
///
/// Android emulator can't reach the host machine via `localhost`, so it
/// needs the special `10.0.2.2` alias. Web/desktop/iOS-simulator can use
/// `localhost` directly.
class ApiConfig {
  ApiConfig._();

  static const int port = 4000;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$port';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:$port';
    } catch (_) {
      // Platform not available (e.g. running in a non-IO environment).
    }
    return 'http://localhost:$port';
  }

  static String get apiUrl => '$baseUrl/api';

  /// Resolves an image path returned by the backend (e.g. "/uploads/x.png")
  /// into a fully-qualified URL the Flutter Image widget can load.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl$path';
  }
}
