import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/customer_me.dart';

class CustomerProfileService {
  CustomerProfileService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<CustomerMe> getMe() async {
    final http.Response response = await _api.get(ApiConstants.authMe);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load profile',
        details: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return CustomerMe.fromJson(decoded);
  }
}
