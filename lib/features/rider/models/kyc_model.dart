/// Rider KYC domain models (frontend-first).
///
/// Notes:
/// - Keeps the model free of plugin-specific types (e.g. XFile) so it remains
///   portable and easy to test.
/// - The UI layer can store picked images as local file paths.
library;

enum KycStatus {
  pending,
  approved,
  rejected,
}

enum KycDocumentType {
  aadhaarFront,
  aadhaarBack,
  panCard,
  drivingLicense,
  vehicleRc,
  selfie,
}

extension KycDocumentTypeX on KycDocumentType {
  String get label {
    switch (this) {
      case KycDocumentType.aadhaarFront:
        return 'Aadhaar Front';
      case KycDocumentType.aadhaarBack:
        return 'Aadhaar Back';
      case KycDocumentType.panCard:
        return 'PAN Card';
      case KycDocumentType.drivingLicense:
        return 'Driving License';
      case KycDocumentType.vehicleRc:
        return 'Vehicle RC';
      case KycDocumentType.selfie:
        return 'Selfie';
    }
  }

  String get backendKey {
    switch (this) {
      case KycDocumentType.aadhaarFront:
        return 'aadhaar_front';
      case KycDocumentType.aadhaarBack:
        return 'aadhaar_back';
      case KycDocumentType.panCard:
        return 'pan';
      case KycDocumentType.drivingLicense:
        return 'license';
      case KycDocumentType.vehicleRc:
        return 'rc';
      case KycDocumentType.selfie:
        return 'selfie';
    }
  }
}

/// A locally selected document.
///
/// [localPath] should be a file path returned by image_picker (`XFile.path`).
class KycDocument {
  const KycDocument({
    required this.type,
    required this.localPath,
  });

  final KycDocumentType type;
  final String localPath;
}

/// KYC submission data for the rider.
///
/// For MVP we store in-memory only via a mock service.
class KycSubmission {
  const KycSubmission({
    required this.documents,
    required this.bankAccountNumber,
    required this.ifscCode,
    this.submittedAt,
  });

  final Map<KycDocumentType, KycDocument> documents;
  final String bankAccountNumber;
  final String ifscCode;
  final DateTime? submittedAt;

  bool hasAllRequiredDocuments() {
    for (final type in KycDocumentType.values) {
      if (!documents.containsKey(type)) return false;
      final path = documents[type]?.localPath.trim() ?? '';
      if (path.isEmpty) return false;
    }
    return true;
  }

  KycSubmission copyWith({
    Map<KycDocumentType, KycDocument>? documents,
    String? bankAccountNumber,
    String? ifscCode,
    DateTime? submittedAt,
  }) {
    return KycSubmission(
      documents: documents ?? this.documents,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

/// KYC record stored by the mock service.
class KycRecord {
  const KycRecord({
    required this.status,
    required this.submission,
    this.rejectionReason,
    this.updatedAt,
  });

  final KycStatus status;
  final KycSubmission submission;
  final String? rejectionReason;
  final DateTime? updatedAt;

  bool get isApproved => status == KycStatus.approved;
  bool get isPending => status == KycStatus.pending;
  bool get isRejected => status == KycStatus.rejected;

  KycRecord copyWith({
    KycStatus? status,
    KycSubmission? submission,
    String? rejectionReason,
    DateTime? updatedAt,
  }) {
    return KycRecord(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Simple validation helpers (UI can also validate with Form validators).
class KycValidators {
  static bool isValidIfsc(String value) {
    final v = value.trim().toUpperCase();
    // Typical IFSC: 4 letters + 0 + 6 alphanumerics (e.g. HDFC0001234)
    final pattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return pattern.hasMatch(v);
  }

  static bool isValidAccountNumber(String value) {
    final v = value.trim();
    // MVP: simple length check; banks vary, commonly 9-18.
    if (v.length < 9 || v.length > 18) return false;
    final digitsOnly = RegExp(r'^[0-9]+$');
    return digitsOnly.hasMatch(v);
  }
}
