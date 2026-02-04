import 'package:flutter/material.dart';

import '../../../core/services/order_service.dart';
import '../screens/new_order_screen.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order #${order.id}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Vendor: ${order.vendorName}'),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(0)}'),
            Text('Status: ${order.status}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewOrderScreen(
                      order: order,
                      orderService: orderService,
                      onAuthExpired: onAuthExpired,
                      onOrderUpdated: onOrderUpdated,
                    ),
                  ),
                );
              },
              child: const Text('Open Order'),
            ),
          ],
        ),
      ),
    );
  }
}
