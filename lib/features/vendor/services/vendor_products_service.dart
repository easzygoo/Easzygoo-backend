import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../api/vendor_api.dart';
import '../models/vendor_product.dart';

class VendorProductsService {
  VendorProductsService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<VendorProduct>> listProducts() async {
    final http.Response response = await _api.get(VendorApi.vendorProducts);
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load products',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final List<dynamic> raw = (data as List<dynamic>);
    return raw
        .whereType<Map>()
        .map((e) => VendorProduct.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<VendorProduct> createProduct(VendorProduct product) async {
    final http.Response response = await _api.postJson(
      VendorApi.vendorProducts,
      body: product.toWriteJson(),
    );

    if (response.statusCode != 201) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to create product',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorProduct.fromJson(json);
  }

  Future<VendorProduct> updateProduct(String id, Map<String, dynamic> patch) async {
    final http.Response response = await _api.patchJson(
      VendorApi.vendorProduct(id),
      body: patch,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to update product',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorProduct.fromJson(json);
  }

  Future<void> deleteProduct(String id) async {
    final http.Response response = await _api.delete(VendorApi.vendorProduct(id));
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to delete product',
        details: response.body,
      );
    }

    // Ensure envelope errors are surfaced.
    await _api.decodeData(response);
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
