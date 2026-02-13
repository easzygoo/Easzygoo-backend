import 'package:flutter/foundation.dart';

import '../models/customer_address.dart';
import '../services/customer_address_service.dart';

class CustomerAddressesController extends ChangeNotifier {
  CustomerAddressesController({required CustomerAddressService addressService})
      : _addresses = addressService;

  final CustomerAddressService _addresses;

  bool _loading = false;
  String? _error;
  List<CustomerAddress> _items = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<CustomerAddress> get items => _items;

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _addresses.listAddresses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    await _addresses.deleteAddress(id);
    await load();
  }

  Future<void> makeDefault(int id) async {
    await _addresses.setDefault(id);
    await load();
  }
}
