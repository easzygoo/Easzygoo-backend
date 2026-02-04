import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../network/api_constants.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: _toDouble(json['price']),
    );
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final int vendorId;
  final String vendorName;
  final int? riderId;
  final String status;
  final double totalAmount;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.vendorName,
    required this.riderId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return OrderModel(
      id: (json['id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      vendorId: (json['vendor_id'] as num?)?.toInt() ?? 0,
      vendorName: (json['vendor_name'] ?? '').toString(),
      riderId: (json['rider_id'] as num?)?.toInt(),
      status: (json['status'] ?? '').toString(),
      totalAmount: _toDouble(json['total_amount']),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      items: rawItems
          .whereType<Map>()
          .map((e) => OrderItem.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

class EarningsSummary {
  final int deliveredOrders;
  final double totalDeliveredAmount;

  EarningsSummary({required this.deliveredOrders, required this.totalDeliveredAmount});

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final deliveredOrders = (json['delivered_orders'] as num?)?.toInt() ?? 0;
    final totalDeliveredAmount = _toDouble(json['total_delivered_amount']);
    return EarningsSummary(deliveredOrders: deliveredOrders, totalDeliveredAmount: totalDeliveredAmount);
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class OrderService {
  OrderService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<OrderModel?> getActiveOrder() async {
    final http.Response response = await _api.get(ApiConstants.ordersAssignedActive);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load active order',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> acceptOrder(String orderId) async {
    final http.Response response = await _api.postJson(ApiConstants.orderAccept(orderId));
    return _decodeOrder(response, fallbackMessage: 'Failed to accept order');
  }

  Future<OrderModel> markPicked(String orderId) async {
    final http.Response response = await _api.postJson(ApiConstants.orderMarkPicked(orderId));
    return _decodeOrder(response, fallbackMessage: 'Failed to mark picked');
  }

  Future<OrderModel> markDelivered(String orderId) async {
    final http.Response response = await _api.postJson(ApiConstants.orderMarkDelivered(orderId));
    return _decodeOrder(response, fallbackMessage: 'Failed to mark delivered');
  }

  Future<EarningsSummary> getEarningsSummary() async {
    final http.Response response = await _api.get(ApiConstants.ordersEarningsSummary);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load earnings summary',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return EarningsSummary.fromJson(data);
  }

  OrderModel _decodeOrder(http.Response response, {required String fallbackMessage}) {
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? fallbackMessage,
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return OrderModel.fromJson(data);
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
