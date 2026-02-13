import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/services/order_service.dart' show OrderModel;

class CustomerOrderService {
  CustomerOrderService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<OrderModel>> listOrders() async {
    final http.Response response = await _api.get(ApiConstants.customerOrders);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load orders',
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    final list = (decoded is List) ? decoded : const [];

    return list
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<OrderModel> getOrder(String orderId) async {
    final http.Response response = await _api.get(
      ApiConstants.customerOrderDetail(orderId),
    );

    if (response.statusCode != 200) {
      final message = _extractMessage(response) ?? 'Failed to load order';
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderModel.fromJson(decoded);
  }

  Future<OrderModel> placeOrder({
    required int vendorId,
    required List<Map<String, dynamic>> items,
    int? addressId,
    String paymentMethod = 'cod',
  }) async {
    final body = <String, dynamic>{
      'vendor_id': vendorId,
      'items': items,
      'payment_method': paymentMethod,
    };
    if (addressId != null) {
      body['address_id'] = addressId;
    }

    final http.Response response = await _api.postJson(
      ApiConstants.customerOrders,
      body: body,
    );

    if (response.statusCode != 201) {
      final message = _extractMessage(response) ?? 'Failed to place order';
      throw ApiException(
        statusCode: response.statusCode,
        message: message,
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderModel.fromJson(decoded);
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
