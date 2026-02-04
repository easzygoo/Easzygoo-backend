class VendorOrderItem {
  VendorOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double price;

  factory VendorOrderItem.fromJson(Map<String, dynamic> json) {
    return VendorOrderItem(
      productId: (json['product_id'] as String?) ?? '',
      productName: (json['product_name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class VendorOrder {
  VendorOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  final String id;
  final String status;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<VendorOrderItem> items;

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? v) {
      if (v == null || v.isEmpty) return null;
      return DateTime.tryParse(v);
    }

    final itemsJson = (json['items'] as List?)?.cast<Map>() ?? const [];

    return VendorOrder(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
      items: itemsJson.map((e) => VendorOrderItem.fromJson(e.cast<String, dynamic>())).toList(),
    );
  }
}
