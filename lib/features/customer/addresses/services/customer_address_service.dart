import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/customer_address.dart';

class CustomerAddressService {
  CustomerAddressService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<CustomerAddress>> listAddresses() async {
    final http.Response response = await _api.get(ApiConstants.customerAddresses);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load addresses',
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    final list = (decoded is List) ? decoded : const [];

    return list
        .whereType<Map>()
        .map((e) => CustomerAddress.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<CustomerAddress> createAddress({
    required Map<String, dynamic> body,
  }) async {
    final http.Response response = await _api.postJson(
      ApiConstants.customerAddresses,
      body: body,
    );

    if (response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to create address',
        details: response.body,
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is Map<String, dynamic>) {
      return CustomerAddress.fromJson(raw);
    }
    throw const FormatException('Unexpected response for createAddress');
  }

  Future<CustomerAddress> updateAddress({
    required int id,
    required Map<String, dynamic> body,
  }) async {
    final http.Response response = await _api.patchJson(
      ApiConstants.customerAddressDetail(id),
      body: body,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to update address',
        details: response.body,
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is Map<String, dynamic>) {
      return CustomerAddress.fromJson(raw);
    }
    throw const FormatException('Unexpected response for updateAddress');
  }

  Future<void> deleteAddress(int id) async {
    final http.Response response = await _api.delete(
      ApiConstants.customerAddressDetail(id),
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to delete address',
        details: response.body,
      );
    }
  }

  Future<CustomerAddress> setDefault(int id) async {
    final http.Response response = await _api.postJson(
      ApiConstants.customerAddressSetDefault(id),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to set default',
        details: response.body,
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is Map<String, dynamic>) {
      return CustomerAddress.fromJson(raw);
    }
    throw const FormatException('Unexpected response for setDefault');
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
      // ignore
    }
    return null;
  }
}
