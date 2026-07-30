import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin wrapper around [http] that talks to the SHC Stock backend,
/// decodes JSON, and turns non-2xx responses into [ApiException].
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path) => Uri.parse('${ApiConfig.apiUrl}$path');

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Request failed';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] != null) message = body['error'].toString();
    } catch (_) {}
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path) async {
    final res = await http.delete(_uri(path));
    _decode(res);
  }

  /// Uploads image bytes to `/api/upload` and returns the relative URL
  /// (e.g. `/uploads/12345.png`) stored by the backend.
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final multipartRequest = http.MultipartRequest('POST', _uri('/upload'))
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamedRes = await multipartRequest.send();
    final res = await http.Response.fromStream(streamedRes);
    final decoded = _decode(res);
    return decoded['url'] as String;
  }
}
