import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'controllers/orders_controller.dart';
import 'order_details_screen.dart';
import 'services/customer_order_service.dart';

class CustomerOrdersTab extends StatefulWidget {
  const CustomerOrdersTab({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CustomerOrdersTab> createState() => CustomerOrdersTabState();
}

class CustomerOrdersTabState extends State<CustomerOrdersTab> {
  late final OrdersController _controller;
  late final CustomerOrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = CustomerOrderService(apiClient: widget.apiClient);
    _controller = OrdersController(
      orderService: _orderService,
    );
    _controller.load();
  }

  Future<void> reload() => _controller.load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final orders = _controller.orders;
        final error = _controller.error;
        final isLoading = _controller.isLoading;

        Widget buildList() {
          if ((error != null && error.isNotEmpty) && orders.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Text(
                  'Failed to load orders\n$error\n\nPull to refresh.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: isLoading ? null : _controller.load,
                  child: const Text('Retry'),
                ),
              ],
            );
          }

          if (orders.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('No orders yet\nPull to refresh.'),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final o = orders[index];
              return Card(
                child: ListTile(
                  title: Text(o.vendorName.isEmpty ? 'Order' : o.vendorName),
                  subtitle: Text('Status: ${o.status}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerOrderDetailsScreen(
                          orderId: o.id,
                          orderService: _orderService,
                        ),
                      ),
                    );
                  },
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${o.totalAmount.toStringAsFixed(2)}'),
                      Text(
                        o.createdAt,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return RefreshIndicator(onRefresh: _controller.load, child: buildList());
      },
    );
  }
}
