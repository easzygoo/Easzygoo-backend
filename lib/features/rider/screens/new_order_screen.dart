import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';
import 'pickup_screen.dart';

/// New order screen (pre-accept).
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({
    super.key,
    required this.order,
    required this.orderService,
    required this.onAuthExpired,
    this.onOrderUpdated,
  });

  final OrderModel order;
  final OrderService orderService;
  final VoidCallback onAuthExpired;
  final VoidCallback? onOrderUpdated;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  bool _submitting = false;

  Future<void> _accept() async {
    setState(() => _submitting = true);
    try {
      final updated = await widget.orderService.acceptOrder(widget.order.id);
      widget.onOrderUpdated?.call();
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PickupScreen(
            order: updated,
            orderService: widget.orderService,
            onAuthExpired: widget.onAuthExpired,
            onOrderUpdated: widget.onOrderUpdated,
          ),
        ),
      );
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onAuthExpired();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept order.')),
      );
    }
  }

  void _reject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reject not supported yet.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Order #${order.id}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(order.vendorName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _KeyValueRow(label: 'Amount', value: _currency(order.totalAmount)),
                  _KeyValueRow(label: 'Status', value: order.status),
                  const SizedBox(height: 12),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 12),
                  Text('Delivery', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('Customer: ${order.customerId}', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Address: (not provided)', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Items', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${item.productName} x${item.quantity}', style: theme.textTheme.bodyMedium),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _reject,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Reject'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _accept,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Accept'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

String _currency(double value) => '₹${value.toStringAsFixed(0)}';
