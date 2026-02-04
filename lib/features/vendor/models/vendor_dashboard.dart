class VendorDashboard {
  VendorDashboard({
    required this.shopName,
    required this.isOpen,
    required this.placedOrders,
    required this.acceptedOrders,
    required this.readyOrders,
    required this.pickedOrders,
    required this.todayOrders,
    required this.todayRevenue,
  });

  final String shopName;
  final bool isOpen;

  final int placedOrders;
  final int acceptedOrders;
  final int readyOrders;
  final int pickedOrders;

  final int todayOrders;
  final double todayRevenue;

  factory VendorDashboard.fromJson(Map<String, dynamic> json) {
    return VendorDashboard(
      shopName: (json['shop_name'] as String?) ?? '',
      isOpen: (json['is_open'] as bool?) ?? false,
      placedOrders: (json['placed_orders'] as num?)?.toInt() ?? 0,
      acceptedOrders: (json['accepted_orders'] as num?)?.toInt() ?? 0,
      readyOrders: (json['ready_orders'] as num?)?.toInt() ?? 0,
      pickedOrders: (json['picked_orders'] as num?)?.toInt() ?? 0,
      todayOrders: (json['today_orders'] as num?)?.toInt() ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
