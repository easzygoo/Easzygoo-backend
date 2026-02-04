import 'dart:convert';

import 'package:http/http.dart' as http;

import '../network/api_client.dart';
import '../network/api_constants.dart';

class KycStatus {
  final bool submitted;
  final String? status;

  KycStatus({required this.submitted, required this.status});

  factory KycStatus.fromJson(Map<String, dynamic> json) {
    return KycStatus(
      submitted: (json['submitted'] as bool?) ?? false,
      status: json['status']?.toString(),
    );
  }
}

class KycService {
  KycService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<KycStatus> getKycStatus() async {
    final http.Response response = await _api.get(ApiConstants.kycStatus);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load KYC status',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    return KycStatus.fromJson(data);
  }

  Future<void> submitKyc({
    required String bankAccount,
    required String ifsc,
    required Map<String, http.MultipartFile> documents,
  }) async {
    final fields = <String, String>{
      'bank_account': bankAccount,
      'ifsc': ifsc,
    };

    final files = <http.MultipartFile>[];

    // Backend expects these exact keys.
    const requiredKeys = <String>{
      'aadhaar_front',
      'aadhaar_back',
      'pan',
      'license',
      'rc',
      'selfie',
    };

    for (final key in requiredKeys) {
      final file = documents[key];
      if (file == null) {
        throw ApiException(message: 'Missing required document: $key');
      }

      // Ensure field name matches expected serializer key.
      files.add(http.MultipartFile(key, file.finalize(), file.length, filename: file.filename, contentType: file.contentType));
    }

    final streamed = await _api.postMultipart(
      ApiConstants.kycSubmit,
      fields: fields,
      files: files,
    );

    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw ApiException(
        statusCode: streamed.statusCode,
        message: _extractMessageFromBody(body) ?? 'Failed to submit KYC',
        details: body,
      );
    }
  }

  Future<String> getSignedDocumentUrl(String documentType, {String? riderUserId}) async {
    final response = await _api.get(
      ApiConstants.kycViewDocument(documentType),
      queryParameters: riderUserId == null ? null : {'rider_user_id': riderUserId},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to get document URL',
        details: response.body,
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url']?.toString();
    if (url == null || url.isEmpty) {
      throw ApiException(message: 'Signed URL missing from response', details: data);
    }
    return url;
  }

  String? _extractMessage(http.Response response) {
    return _extractMessageFromBody(response.body);
  }

  String? _extractMessageFromBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {
      // Ignore JSON parse errors.
    }
    return null;
  }
}
