import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/order_service.dart' show OrderModel;
import 'services/customer_order_service.dart';

class CustomerOrderDetailsScreen extends StatefulWidget {
  const CustomerOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderService,
  });

  final String orderId;
  final CustomerOrderService orderService;

  @override
  State<CustomerOrderDetailsScreen> createState() =>
      _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState extends State<CustomerOrderDetailsScreen> {
  bool _loading = false;
  String? _error;
  OrderModel? _order;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _shouldPoll(OrderModel order) {
    final status = order.status.toLowerCase();
    return status != 'delivered' && status != 'cancelled';
  }

  void _configurePollingIfNeeded() {
    _pollTimer?.cancel();

    final order = _order;
    if (order == null) return;
    if (!_shouldPoll(order)) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_load(silent: true));
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (_loading) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      _error = null;
      _loading = true;
    }

    try {
      final order = await widget.orderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _error = null;
        });
        _configurePollingIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_loading && order == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_error != null && order == null)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Text(
                      'Failed to load order\n${_error!}\n\nPull to refresh.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _loading ? null : _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (order == null)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Text('Order not found', textAlign: TextAlign.center),
              )
            else ...[
              Text(
                order.vendorName.isEmpty ? 'Order' : order.vendorName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Status: ${order.status}'),
              const SizedBox(height: 4),
              Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Text('Placed: ${order.createdAt}'),
              const SizedBox(height: 4),
              Text('Updated: ${order.updatedAt}'),
              if (order.riderId != null) ...[
                const SizedBox(height: 4),
                Text('Rider: #${order.riderId}'),
              ],
              const SizedBox(height: 12),
              Text(
                'Payment: ${order.paymentMethod.isEmpty ? '—' : order.paymentMethod} (${order.paymentStatus.isEmpty ? '—' : order.paymentStatus})',
              ),
              const SizedBox(height: 4),
              Text(
                'Delivery: ${order.deliveryAddress?.summary ?? (order.deliveryAddressId == null ? '—' : 'Address #${order.deliveryAddressId}')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                const Text('No items')
              else
                ...order.items.map(
                  (i) => Card(
                    child: ListTile(
                      title: Text(i.productName),
                      subtitle: Text('Qty: ${i.quantity}'),
                      trailing: Text('₹${(i.price * i.quantity).toStringAsFixed(2)}'),
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Last update failed: ${_error!}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              if (_shouldPoll(order))
                Text(
                  'Tracking: auto-refreshing every 10s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
