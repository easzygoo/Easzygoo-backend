import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../api/vendor_api.dart';
import '../models/vendor_sales_summary.dart';

class VendorSalesService {
  VendorSalesService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<VendorSalesSummary> salesSummary({int days = 7}) async {
    final http.Response response = await _api.get(VendorApi.vendorsSalesSummary(days: days));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load sales summary',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorSalesSummary.fromJson(json);
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
