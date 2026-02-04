import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_constants.dart';

class AuthExpiredException implements Exception {
  final String message;
  AuthExpiredException([this.message = 'Authentication expired']);

  @override
  String toString() => 'AuthExpiredException: $message';
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? details;

  ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _http = httpClient ?? http.Client(),
        _storage = secureStorage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';

  final http.Client _http;
  final FlutterSecureStorage _storage;

  Future<void> setAccessToken(String token) => _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(ApiConstants.baseUrl);
    return Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: _joinPath(base.path, path),
      queryParameters: (queryParameters == null || queryParameters.isEmpty) ? null : queryParameters,
    );
  }

  String _joinPath(String a, String b) {
    final left = a.endsWith('/') ? a.substring(0, a.length - 1) : a;
    final right = b.startsWith('/') ? b.substring(1) : b;
    if (left.isEmpty) return '/$right';
    return '$left/$right';
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra, bool json = true}) async {
    final headers = <String, String>{
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
      if (json) ApiConstants.headerContentType: ApiConstants.contentTypeJson,
    };

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers[ApiConstants.headerAuthorization] = ApiConstants.bearer(token);
    }

    if (extra != null && extra.isNotEmpty) {
      headers.addAll(extra);
    }

    return headers;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final response = await _http
        .get(uri, headers: await _headers(extra: headers))
        .timeout(ApiConstants.receiveTimeout);

    await _handleAuthIfNeeded(response);
    return response;
  }

  Future<http.Response> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final response = await _http
        .post(
          uri,
          headers: await _headers(extra: headers, json: true),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(ApiConstants.receiveTimeout);

    await _handleAuthIfNeeded(response);
    return response;
  }

  Future<http.Response> putJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final response = await _http
        .put(
          uri,
          headers: await _headers(extra: headers, json: true),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(ApiConstants.receiveTimeout);

    await _handleAuthIfNeeded(response);
    return response;
  }

  Future<http.Response> patchJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final response = await _http
        .patch(
          uri,
          headers: await _headers(extra: headers, json: true),
          body: jsonEncode(body ?? const {}),
        )
        .timeout(ApiConstants.receiveTimeout);

    await _handleAuthIfNeeded(response);
    return response;
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final response = await _http
        .delete(uri, headers: await _headers(extra: headers))
        .timeout(ApiConstants.receiveTimeout);

    await _handleAuthIfNeeded(response);
    return response;
  }

  Future<http.StreamedResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path, queryParameters);
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll(fields);
    request.files.addAll(files);

    // MultipartRequest sets its own content-type/boundary.
    request.headers.addAll(await _headers(extra: headers, json: false));
    request.headers.remove(ApiConstants.headerContentType);

    final streamed = await request.send().timeout(ApiConstants.receiveTimeout);

    if (streamed.statusCode == 401) {
      await clearAccessToken();
      throw AuthExpiredException();
    }

    return streamed;
  }

  Future<Map<String, dynamic>> decodeJson(http.Response response) async {
    await _handleAuthIfNeeded(response);

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  /// Decodes JSON and unwraps the backend response envelope when present.
  ///
  /// Supports both styles:
  /// - Envelope: {"success": true, "data": ...} / {"success": false, "error": "..."}
  /// - Plain DRF: {...} or [...]
  ///
  /// Throws [ApiException] when an envelope indicates failure.
  Future<Object?> decodeData(http.Response response) async {
    await _handleAuthIfNeeded(response);

    if (response.body.isEmpty) return null;

    final Object decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      final success = decoded['success'];
      if (success == true) {
        return decoded['data'];
      }

      final error = decoded['error'];
      throw ApiException(
        statusCode: response.statusCode,
        message: (error is String && error.isNotEmpty) ? error : 'Request failed',
        details: decoded,
      );
    }

    return decoded;
  }

  Future<void> _handleAuthIfNeeded(http.BaseResponse response) async {
    if (response.statusCode == 401) {
      await clearAccessToken();
      throw AuthExpiredException();
    }
  }

  void dispose() {
    _http.close();
  }
}
