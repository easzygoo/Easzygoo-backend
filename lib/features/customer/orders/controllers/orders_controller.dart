import 'package:flutter/foundation.dart';

import '../../../../core/services/order_service.dart' show OrderModel;
import '../services/customer_order_service.dart';

class OrdersController extends ChangeNotifier {
  OrdersController({required CustomerOrderService orderService})
    : _orders = orderService;

  final CustomerOrderService _orders;

  bool _loading = false;
  String? _error;
  List<OrderModel> _items = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<OrderModel> get orders => _items;

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _orders.listOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
