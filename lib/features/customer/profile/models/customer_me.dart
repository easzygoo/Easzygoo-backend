class CustomerMe {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String createdAt;

  CustomerMe({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  factory CustomerMe.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      throw StateError('CustomerMe.fromJson: missing id');
    }
    return CustomerMe(
      id: id,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
