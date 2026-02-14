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
  bool _disposed = false;

  bool get isLoading => _loading;
  String? get error => _error;
  List<OrderModel> get orders => _items;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final items = await _orders.listOrders();
      if (_disposed) return;
      _items = items;
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
    } finally {
      if (_disposed) return;
      _loading = false;
      notifyListeners();
    }
  }
}
