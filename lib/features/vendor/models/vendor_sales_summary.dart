class VendorSalesSummary {
  VendorSalesSummary({
    required this.todayTotalSales,
    required this.completedOrdersCount,
    required this.pendingOrdersCount,
  });

  final double todayTotalSales;
  final int completedOrdersCount;
  final int pendingOrdersCount;

  factory VendorSalesSummary.fromJson(Map<String, dynamic> json) {
    return VendorSalesSummary(
      todayTotalSales: (json['today_total_sales'] as num?)?.toDouble() ?? 0.0,
      completedOrdersCount: (json['completed_orders_count'] as num?)?.toInt() ?? 0,
      pendingOrdersCount: (json['pending_orders_count'] as num?)?.toInt() ?? 0,
    );
  }
}
