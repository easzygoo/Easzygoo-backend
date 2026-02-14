import 'package:flutter/foundation.dart';

import '../models/customer_product.dart';
import '../services/catalog_service.dart';
import '../../orders/services/customer_order_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required CatalogService catalogService,
    required CustomerOrderService orderService,
  }) : _catalog = catalogService,
       _orders = orderService;

  final CatalogService _catalog;
  final CustomerOrderService _orders;

  bool _loading = false;
  String? _error;
  List<CustomerProduct> _products = const [];

  int? _cartVendorId;
  final Map<String, int> _cartQtyByProductId = <String, int>{};

  bool get isLoading => _loading;
  String? get error => _error;
  List<CustomerProduct> get products => _products;

  int get cartItemCount => _cartQtyByProductId.values.fold(0, (a, b) => a + b);

  int quantityFor(String productId) => _cartQtyByProductId[productId] ?? 0;

  double get cartTotal {
    double total = 0.0;
    for (final p in _products) {
      final qty = _cartQtyByProductId[p.id] ?? 0;
      if (qty > 0) total += p.price * qty;
    }
    return total;
  }

  void _reconcileCartAfterProductRefresh() {
    if (_cartQtyByProductId.isEmpty) {
      _cartVendorId = null;
      return;
    }

    final productById = <String, CustomerProduct>{
      for (final p in _products) p.id: p,
    };

    final toRemove = <String>[];
    for (final entry in _cartQtyByProductId.entries) {
      final p = productById[entry.key];
      if (p == null) {
        toRemove.add(entry.key);
        continue;
      }

      if (_cartVendorId != null && p.vendorId != _cartVendorId) {
        toRemove.add(entry.key);
        continue;
      }

      final clamped = entry.value.clamp(0, p.stock);
      if (clamped == 0) {
        toRemove.add(entry.key);
      } else if (clamped != entry.value) {
        _cartQtyByProductId[entry.key] = clamped;
      }
    }

    for (final id in toRemove) {
      _cartQtyByProductId.remove(id);
    }

    if (_cartQtyByProductId.isEmpty) {
      _cartVendorId = null;
    } else if (_cartVendorId == null) {
      final firstId = _cartQtyByProductId.keys.first;
      _cartVendorId = productById[firstId]?.vendorId;
    }
  }

  Future<void> load() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _catalog.listProducts();
      _reconcileCartAfterProductRefresh();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String? addToCart(CustomerProduct product) {
    if (_cartVendorId != null && _cartVendorId != product.vendorId) {
      return 'You can order from only one shop at a time.';
    }

    _cartVendorId ??= product.vendorId;
    final current = _cartQtyByProductId[product.id] ?? 0;
    if (product.stock <= 0 || current >= product.stock) {
      return 'Out of stock';
    }

    _cartQtyByProductId[product.id] = current + 1;
    notifyListeners();
    return null;
  }

  void removeFromCart(CustomerProduct product) {
    final current = _cartQtyByProductId[product.id] ?? 0;
    if (current <= 1) {
      _cartQtyByProductId.remove(product.id);
    } else {
      _cartQtyByProductId[product.id] = current - 1;
    }

    if (_cartQtyByProductId.isEmpty) {
      _cartVendorId = null;
    }

    notifyListeners();
  }

  Future<String?> placeOrder({required int addressId, String paymentMethod = 'cod'}) async {
    if (_loading) return 'Please wait…';
    if (_cartVendorId == null || _cartQtyByProductId.isEmpty) {
      return 'Add items to cart';
    }
    if (addressId <= 0) {
      return 'Select a delivery address';
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final items = _cartQtyByProductId.entries
          .map(
            (e) => <String, dynamic>{'product_id': e.key, 'quantity': e.value},
          )
          .toList(growable: false);

      await _orders.placeOrder(
        vendorId: _cartVendorId!,
        items: items,
        addressId: addressId,
        paymentMethod: paymentMethod,
      );
      _cartQtyByProductId.clear();
      _cartVendorId = null;

      try {
        _products = await _catalog.listProducts();
      } catch (_) {
        // Ignore refresh failures here; order was placed successfully.
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
