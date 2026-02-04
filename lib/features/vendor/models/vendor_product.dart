class VendorProduct {
  VendorProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool isActive;

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    return VendorProduct(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'is_active': isActive,
    };
  }
}
