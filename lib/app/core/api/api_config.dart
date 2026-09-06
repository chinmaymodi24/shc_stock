import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:shc_stock/app/core/api/backend_host.g.dart';

/// Central place for the backend base URL.
///
/// Local dev has two ways for an Android device to reach the backend, and we
/// no longer guess between them — [candidateBaseUrls] lists both and
/// `ApiClient` probes `/api/health` once at startup, keeping whichever answers:
///
///  * **Wi-Fi, no cable** — the dev machine's LAN IP, baked into
///    `backend_host.g.dart` by android/app/build.gradle.kts. Needs the PC
///    firewall to allow inbound TCP 4000, and the debug network security config
///    (android/app/src/debug/res/xml) to permit cleartext HTTP.
///  * **`localhost`** — reaches the dev machine through `adb reverse
///    tcp:4000 tcp:4000`, which every debug build sets up. Covers the emulator
///    and a cabled (or wireless-adb) phone.
///
/// Probing instead of picking means an unplugged cable, a changed LAN IP, or a
/// Wi-Fi/USB switch degrades to the other route instead of failing every call
/// with "Something went wrong". Web/desktop/iOS-simulator just use `localhost`.
///
/// Overrides (skip probing entirely): `--dart-define=API_URL=` (full prod URL)
/// or `--dart-define=API_HOST=` (pin one LAN IP).
class ApiConfig {
  ApiConfig._();

  static const int port = 4000;

  /// Production backend URL, injected at build time:
  ///   flutter build web --dart-define=API_URL=https://shc-stock-api.onrender.com
  /// When empty (local dev) we fall back to localhost / the LAN IP.
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Host-only override — pin a specific LAN IP instead of the generated one:
  ///   flutter run --dart-define=API_HOST=192.168.1.6
  static const String _envHost = String.fromEnvironment('API_HOST');

  static const String _localhostUrl = 'http://localhost:$port';

  /// True when a real (non-emulator-safe) LAN address was baked in for a debug
  /// Android build — the only case where probing has anything to choose from.
  static bool get _hasLanCandidate =>
      !kIsWeb &&
      !kReleaseMode &&
      defaultTargetPlatform == TargetPlatform.android &&
      kGeneratedDevBackendHost.isNotEmpty;

  /// Base URLs to try, best first. `ApiClient` keeps the first one whose
  /// `/api/health` responds and stores it in [resolvedBaseUrl].
  static List<String> get candidateBaseUrls {
    if (_envUrl.isNotEmpty) return [_envUrl];
    if (_envHost.isNotEmpty) return ['http://$_envHost:$port'];
    // LAN first: it survives the cable being unplugged, localhost does not.
    if (_hasLanCandidate) {
      return ['http://$kGeneratedDevBackendHost:$port', _localhostUrl];
    }
    return [_localhostUrl];
  }

  /// Set by `ApiClient` once probing picks a reachable host. Null until then.
  static String? resolvedBaseUrl;

  /// The host currently in use — the probed one when known, else the best guess.
  static String get baseUrl => resolvedBaseUrl ?? candidateBaseUrls.first;

  static String get apiUrl => '$baseUrl/api';

  /// Resolves an image path returned by the backend (e.g. "/uploads/x.png")
  /// into a fully-qualified URL the Flutter Image widget can load.
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl$path';
  }
}
