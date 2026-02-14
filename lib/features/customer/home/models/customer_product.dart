class CustomerProduct {
  CustomerProduct({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.isActive,
  });

  final String id;
  final int vendorId;
  final String vendorName;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool isActive;

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory CustomerProduct.fromJson(Map<String, dynamic> json) {
    return CustomerProduct(
      id: (json['id'] ?? '').toString(),
      vendorId: (json['vendor_id'] as num?)?.toInt() ?? 0,
      vendorName: (json['vendor_name'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: _toDouble(json['price']),
      stock: _toInt(json['stock']),
      isActive: (json['is_active'] as bool?) ?? false,
    );
  }
}
