import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../network/api_constants.dart';

class RiderProfile {
  final String userId;
  final String name;
  final String phone;
  final bool isOnline;
  final String kycStatus;
  final double? currentLat;
  final double? currentLng;

  RiderProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.isOnline,
    required this.kycStatus,
    required this.currentLat,
    required this.currentLng,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isOnline: (json['is_online'] as bool?) ?? false,
      kycStatus: (json['kyc_status'] ?? '').toString(),
      currentLat: _toDouble(json['current_lat']),
      currentLng: _toDouble(json['current_lng']),
    );
  }
}

class RiderService {
  RiderService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<RiderProfile> getProfile() async {
    final http.Response response = await _api.get(ApiConstants.ridersMe);
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load rider profile',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return RiderProfile.fromJson(data);
  }

  Future<RiderProfile> toggleOnline({required bool isOnline}) async {
    final http.Response response = await _api.postJson(
      ApiConstants.ridersToggleOnline,
      body: {'is_online': isOnline},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to update online status',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return RiderProfile.fromJson(data);
  }

  Future<RiderProfile> updateLocation({required double lat, required double lng}) async {
    final http.Response response = await _api.postJson(
      ApiConstants.ridersUpdateLocation,
      body: {'current_lat': lat, 'current_lng': lng},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to update location',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return RiderProfile.fromJson(data);
  }

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
