class CustomerAddress {
  final int id;
  final String label;
  final String receiverName;
  final String receiverPhone;
  final String line1;
  final String line2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  CustomerAddress({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.receiverPhone,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'yes' || t == 'y') return true;
      if (t == 'false' || t == '0' || t == 'no' || t == 'n') return false;
    }
    return false;
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString(),
      receiverName: (json['receiver_name'] ?? '').toString(),
      receiverPhone: (json['receiver_phone'] ?? '').toString(),
      line1: (json['line1'] ?? '').toString(),
      line2: (json['line2'] ?? '').toString(),
      landmark: (json['landmark'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      isDefault: _parseBool(json['is_default']),
    );
  }

  String get shortSummary {
    final parts = <String>[];
    if (line1.isNotEmpty) parts.add(line1);
    if (city.isNotEmpty) parts.add(city);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }
}
