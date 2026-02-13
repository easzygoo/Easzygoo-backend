import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/customer_product.dart';

class CatalogService {
  CatalogService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<CustomerProduct>> listProducts() async {
    final http.Response response = await _api.get(ApiConstants.catalogProducts);

    if (response.statusCode != 200) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to load products',
        details: response.body,
      );
    }

    final data = await _api.decodeData(response);
    final list = (data is List) ? data : const [];

    return list
        .whereType<Map>()
        .map((e) => CustomerProduct.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
