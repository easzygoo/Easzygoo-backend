import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../api/vendor_api.dart';
import '../models/vendor_order.dart';

class VendorOrdersService {
  VendorOrdersService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<VendorOrder>> listOrders({String? status}) async {
    final http.Response response = await _api.get(
      VendorApi.vendorOrders,
      queryParameters: (status == null || status.isEmpty) ? null : {'status': status},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load orders',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final List<dynamic> raw = (data as List<dynamic>);
    return raw
        .whereType<Map>()
        .map((e) => VendorOrder.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<VendorOrder> markReady(String id) async {
    final http.Response response = await _api.postJson(VendorApi.vendorOrderReady(id));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to mark ready',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorOrder.fromJson(json);
  }

  Future<VendorOrder> cancel(String id) async {
    final http.Response response = await _api.postJson(VendorApi.vendorOrderCancel(id));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to cancel order',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorOrder.fromJson(json);
  }

  Future<VendorOrder> accept(String id) async {
    final http.Response response = await _api.postJson(VendorApi.vendorOrderAccept(id));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to accept order',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorOrder.fromJson(json);
  }

  Future<VendorOrder> reject(String id) async {
    final http.Response response = await _api.postJson(VendorApi.vendorOrderReject(id));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to reject order',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorOrder.fromJson(json);
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
