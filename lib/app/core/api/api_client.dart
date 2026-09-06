import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shc_stock/app/core/api/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Structured detail payload some endpoints attach to error responses —
  /// e.g. the insufficient-stock shortfall list from `/sales-orders`
  /// (`[{productId, product, requested, available}, ...]`). Null when the
  /// backend didn't send one.
  final dynamic details;

  ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around [Dio] that talks to the SHC Stock backend and turns
/// non-2xx responses into [ApiException].
///
/// Project convention: all API calls go through Dio — never `http` — so any
/// new module wiring up a backend call should use this client.
class ApiClient {
  ApiClient._() : _dio = Dio(BaseOptions(baseUrl: ApiConfig.apiUrl));
  static final ApiClient instance = ApiClient._();

  final Dio _dio;

  /// Artificial delay added to every request so loading states/animations
  /// are actually visible during development. Project convention — keep
  /// this on for every API call, current and future.
  static const Duration artificialDelay = Duration(seconds: 1);

  Future<void> _delay() => Future.delayed(artificialDelay);

  /// Runs once, on the first request, and never again.
  Future<void>? _hostProbe;

  /// How long a single candidate gets to answer `/api/health`. Both candidates
  /// are on the local network, so a reachable one replies in a few ms; this is
  /// only the ceiling for the unreachable one.
  static const Duration _probeTimeout = Duration(seconds: 2);

  /// Picks the first base URL from [ApiConfig.candidateBaseUrls] whose
  /// `/api/health` responds, and points [_dio] at it.
  ///
  /// Why probe instead of picking at build time: a phone reaches the dev
  /// backend either by its LAN IP (Wi-Fi, no cable) or via `localhost` through
  /// `adb reverse` (cable/emulator), and which one works flips the moment the
  /// cable moves or the machine's IP changes. Hard-coding either meant every
  /// call failed with a generic "Something went wrong" whenever the assumption
  /// broke. Costs one short request at startup and nothing after that.
  Future<void> _ensureHost() {
    return _hostProbe ??= _probeHost();
  }

  Future<void> _probeHost() async {
    final candidates = ApiConfig.candidateBaseUrls;
    if (candidates.length == 1) {
      ApiConfig.resolvedBaseUrl = candidates.first;
      _dio.options.baseUrl = '${candidates.first}/api';
      return;
    }

    final probe = Dio(
      BaseOptions(connectTimeout: _probeTimeout, receiveTimeout: _probeTimeout),
    );
    for (final base in candidates) {
      try {
        await probe.get('$base/api/health');
        ApiConfig.resolvedBaseUrl = base;
        _dio.options.baseUrl = '$base/api';
        debugPrint('ApiClient: backend reachable at $base');
        return;
      } on DioException {
        debugPrint('ApiClient: $base unreachable, trying next');
      }
    }
    // Nothing answered (backend down, firewall, wrong network). Keep the first
    // candidate so the real request produces a proper error, and let the next
    // call retry the probe rather than caching the failure for the session.
    _hostProbe = null;
    ApiConfig.resolvedBaseUrl = null;
    _dio.options.baseUrl = '${candidates.first}/api';
  }

  dynamic _unwrap(Response res) => res.data;

  Never _throwFrom(DioException e) {
    final res = e.response;
    String message = 'Request failed';
    dynamic details;
    final data = res?.data;
    if (data is Map && data['error'] != null) {
      message = data['error'].toString();
      details = data['details'];
    } else if (e.message != null) {
      message = e.message!;
    }
    throw ApiException(res?.statusCode ?? -1, message, details: details);
  }

  Future<dynamic> get(String path) async {
    try {
      await _ensureHost();
      final res = await _dio.get(path);
      await _delay();
      return _unwrap(res);
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      await _ensureHost();
      final res = await _dio.post(path, data: body);
      await _delay();
      return _unwrap(res);
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      await _ensureHost();
      final res = await _dio.put(path, data: body);
      await _delay();
      return _unwrap(res);
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      await _ensureHost();
      final res = await _dio.patch(path, data: body);
      await _delay();
      return _unwrap(res);
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _ensureHost();
      await _dio.delete(path);
      await _delay();
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  /// DELETE that returns the response body — for endpoints that answer with
  /// the updated resource instead of 204 (e.g. undoing a stock adjustment
  /// returns the recalculated inventory row).
  Future<dynamic> deleteJson(String path) async {
    try {
      await _ensureHost();
      final res = await _dio.delete(path);
      await _delay();
      return _unwrap(res);
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }

  /// Uploads image bytes to `/api/upload` and returns the relative URL
  /// (e.g. `/uploads/12345.png`) stored by the backend.
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    try {
      await _ensureHost();
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post('/upload', data: form);
      await _delay();
      final decoded = _unwrap(res);
      return decoded['url'] as String;
    } on DioException catch (e) {
      await _delay();
      _throwFrom(e);
    }
  }
}
