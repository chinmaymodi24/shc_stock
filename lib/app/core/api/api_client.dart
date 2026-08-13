import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_config.dart';

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
