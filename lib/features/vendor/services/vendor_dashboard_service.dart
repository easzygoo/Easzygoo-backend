import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../api/vendor_api.dart';
import '../models/vendor_dashboard.dart';

class VendorDashboardService {
  VendorDashboardService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<VendorDashboard> fetchDashboard() async {
    final http.Response response = await _api.get(VendorApi.vendorsDashboard);
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load dashboard',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorDashboard.fromJson(json);
  }

  String? _extractMessage(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {}
    return null;
  }
}
