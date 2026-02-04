class VendorProfile {
  VendorProfile({
    required this.id,
    required this.shopName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
  });

  final int id;
  final String shopName;
  final String address;
  final double latitude;
  final double longitude;
  final bool isOpen;

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shopName: (json['shop_name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? double.nan,
      longitude: (json['longitude'] as num?)?.toDouble() ?? double.nan,
      isOpen: (json['is_open'] as bool?) ?? false,
    );
  }
}
