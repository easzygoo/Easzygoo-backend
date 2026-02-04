class VendorVerificationStatus {
  VendorVerificationStatus({
    required this.submitted,
    required this.status,
  });

  final bool submitted;
  final String? status;

  factory VendorVerificationStatus.fromJson(Map<String, dynamic> json) {
    return VendorVerificationStatus(
      submitted: (json['submitted'] as bool?) ?? false,
      status: json['status'] as String?,
    );
  }
}
