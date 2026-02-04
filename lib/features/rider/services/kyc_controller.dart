import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/kyc_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/kyc_service.dart' as api;

/// Simple ChangeNotifier state for Rider KYC.
///
/// UI uses this controller to:
/// - read current KYC status
/// - submit KYC
/// - react to pending/approved/rejected states
class KycController extends ChangeNotifier {
  KycController({
    required api.KycService service,
    VoidCallback? onAuthExpired,
  })  : _service = service,
        _onAuthExpired = onAuthExpired;

  final api.KycService _service;
  final VoidCallback? _onAuthExpired;

  bool _loading = false;
  String? _errorMessage;
  bool _submitted = false;
  KycStatus? _status;

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  KycStatus? get status => _status;

  bool get hasSubmission => _submitted;
  bool get isApproved => _status == KycStatus.approved;
  bool get isPending => _status == KycStatus.pending;
  bool get isRejected => _status == KycStatus.rejected;

  Future<void> load() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final api.KycStatus result = await _service.getKycStatus();
      _submitted = result.submitted;
      _status = _parseStatus(result.status);
    } on AuthExpiredException {
      _errorMessage = 'Session expired. Please login again.';
      _onAuthExpired?.call();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load KYC status.';
      if (kDebugMode) {
        debugPrint('KycController.load error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submit(KycSubmission submission) async {
    _errorMessage = null;

    if (!submission.hasAllRequiredDocuments()) {
      _errorMessage = 'Upload all required documents.';
      notifyListeners();
      return;
    }

    if (!KycValidators.isValidAccountNumber(submission.bankAccountNumber)) {
      _errorMessage = 'Enter a valid bank account number.';
      notifyListeners();
      return;
    }

    if (!KycValidators.isValidIfsc(submission.ifscCode)) {
      _errorMessage = 'Enter a valid IFSC code.';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final documents = <String, http.MultipartFile>{};
      for (final type in KycDocumentType.values) {
        final doc = submission.documents[type];
        final path = doc?.localPath.trim() ?? '';
        if (path.isEmpty) {
          throw ApiException(message: 'Missing required document: ${type.label}');
        }
        documents[type.backendKey] = await http.MultipartFile.fromPath(type.backendKey, path);
      }

      await _service.submitKyc(
        bankAccount: submission.bankAccountNumber.trim(),
        ifsc: submission.ifscCode.trim().toUpperCase(),
        documents: documents,
      );

      _submitted = true;
      _status = KycStatus.pending;
    } on AuthExpiredException {
      _errorMessage = 'Session expired. Please login again.';
      _onAuthExpired?.call();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'KYC submission failed.';
      if (kDebugMode) {
        debugPrint('KycController.submit error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reset() async {
    _errorMessage = null;
    _submitted = false;
    _status = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  KycStatus? _parseStatus(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return switch (v) {
      'approved' => KycStatus.approved,
      'rejected' => KycStatus.rejected,
      'pending' => KycStatus.pending,
      _ => null,
    };
  }
}
