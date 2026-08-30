/// Central place for the backend base URL.
///
/// On Android (emulator *and* a USB-connected physical device) we hit
/// `localhost:4000` and rely on `adb reverse tcp:4000 tcp:4000` tunnelling
/// that to the dev machine — one mechanism for both, and it's the "before
/// launch" step on the IDE run configs. The old `10.0.2.2` alias only worked
/// on the emulator and left real phones with "Something went wrong".
/// Web/desktop/iOS-simulator use `localhost` directly.
/// Overrides: `--dart-define=API_URL=` (full prod URL) or
/// `--dart-define=API_HOST=` (LAN IP, for Wi-Fi instead of USB).
class ApiConfig {
  ApiConfig._();

  static const int port = 4000;

  /// Production backend URL, injected at build time:
  ///   flutter build web --dart-define=API_URL=https://shc-stock-api.onrender.com
  /// When empty (local dev) we fall back to localhost / the emulator alias.
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Host-only override — the dev machine's LAN IP, for running on a physical
  /// device over Wi-Fi instead of USB (no `adb reverse`, but the PC firewall
  /// must allow port 4000):
  ///   flutter run --dart-define=API_HOST=192.168.1.6
  static const String _envHost = String.fromEnvironment('API_HOST');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (_envHost.isNotEmpty) return 'http://$_envHost:$port';
    // Android too: `adb reverse tcp:4000 tcp:4000` makes the device's own
    // localhost:4000 reach the dev machine (works on emulator and a real
    // USB-connected phone alike).
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
