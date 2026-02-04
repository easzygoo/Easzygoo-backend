class VendorSalesDay {
  VendorSalesDay({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  final DateTime date;
  final int orders;
  final double revenue;

  factory VendorSalesDay.fromJson(Map<String, dynamic> json) {
    final dateStr = (json['date'] as String?) ?? '';
    final dt = DateTime.tryParse(dateStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return VendorSalesDay(
      date: dt,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
