import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../network/api_constants.dart';

class LoginResult {
  final Map<String, dynamic> user;
  final String accessToken;
  final String? refreshToken;

  LoginResult({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });
}

class AuthService {
  AuthService({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _api = apiClient,
        _storage = secureStorage ?? const FlutterSecureStorage();

  static const String _refreshTokenKey = 'refresh_token';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<LoginResult> login({required String phone, required String otp, String? role}) async {
    final http.Response response = await _api.postJson(
      ApiConstants.authLogin,
      body: {
        'phone': phone,
        'otp': otp,
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Login failed',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

    final String? access = data['access'] as String?;
    final String? refresh = data['refresh'] as String?;
    final Map<String, dynamic> user = (data['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    if (access == null || access.isEmpty) {
      throw ApiException(message: 'Login response missing access token', details: data);
    }

    await _api.setAccessToken(access);

    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: refresh);
    }

    return LoginResult(user: user, accessToken: access, refreshToken: refresh);
  }

  Future<void> logout() async {
    await _api.clearAccessToken();
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> getStoredToken() => _api.getAccessToken();

  Future<String?> getStoredRefreshToken() => _storage.read(key: _refreshTokenKey);

  String? _extractMessage(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {
      // Ignore JSON parse errors.
    }
    return null;
  }
}
