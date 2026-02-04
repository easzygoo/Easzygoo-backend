import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../api/vendor_api.dart';
import '../models/vendor_verification_status.dart';

class VendorVerificationService {
  VendorVerificationService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<VendorVerificationStatus> status() async {
    final http.Response response = await _api.get(VendorApi.vendorsVerificationStatus);
    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response) ?? 'Failed to load verification status',
        details: response.body,
      );
    }

    final Object? data = await _api.decodeData(response);
    final Map<String, dynamic> json = (data as Map).cast<String, dynamic>();
    return VendorVerificationStatus.fromJson(json);
  }

  Future<void> submit({
    required http.MultipartFile idFront,
    required http.MultipartFile idBack,
    required http.MultipartFile shopLicense,
    required http.MultipartFile selfie,
  }) async {
    final http.StreamedResponse streamed = await _api.postMultipart(
      VendorApi.vendorsVerificationSubmit,
      fields: const <String, String>{},
      files: <http.MultipartFile>[idFront, idBack, shopLicense, selfie],
    );

    final String body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 201) {
      throw ApiException(
        statusCode: streamed.statusCode,
        message: _extractMessageFromBody(body) ?? 'Failed to submit verification',
        details: body,
      );
    }

    // Surface envelope errors (if any) even on 201.
    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('success') && decoded['success'] != true) {
        final err = decoded['error'];
        throw ApiException(
          statusCode: streamed.statusCode,
          message: (err is String && err.isNotEmpty) ? err : 'Failed to submit verification',
          details: decoded,
        );
      }
    }
  }

  String? _extractMessage(http.Response response) {
    if (response.body.isEmpty) return null;
    return _extractMessageFromBody(response.body);
  }

  String? _extractMessageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.isNotEmpty) return error;
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {}
    return null;
  }
}
