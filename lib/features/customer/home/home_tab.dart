import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'controllers/home_controller.dart';
import 'models/customer_product.dart';
import 'services/catalog_service.dart';
import '../orders/services/customer_order_service.dart';
import '../addresses/addresses_screen.dart';
import '../addresses/models/customer_address.dart';
import '../addresses/services/customer_address_service.dart';

class CustomerHomeTab extends StatefulWidget {
  const CustomerHomeTab({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CustomerHomeTab> createState() => _CustomerHomeTabState();
}

class _CustomerHomeTabState extends State<CustomerHomeTab> {
  late final HomeController _controller;
  CustomerAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      catalogService: CatalogService(apiClient: widget.apiClient),
      orderService: CustomerOrderService(apiClient: widget.apiClient),
    );
    _controller.load();

    CustomerAddressService(apiClient: widget.apiClient)
        .listAddresses()
        .then((list) {
          if (!mounted || list.isEmpty) return;
          final def = list.where((a) => a.isDefault).toList();
          setState(() => _selectedAddress = def.isNotEmpty ? def.first : list.first);
        })
        .catchError((_) {
          // Ignore address preload failures; user can select manually.
        });
  }

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
        final products = _controller.products;
        final hasCart = _controller.cartItemCount > 0;

        Widget buildList() {
          final error = _controller.error;
          final isLoading = _controller.isLoading;

          if ((error != null && error.isNotEmpty) && products.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Text(
                  'Failed to load products\n$error\n\nPull to refresh.',
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

          if (products.isEmpty) {
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
                      : const Text('No products yet\nPull to refresh.'),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final CustomerProduct p = products[index];
              final qty = _controller.quantityFor(p.id);

              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    p.vendorName.isEmpty
                        ? (p.description.isEmpty ? '—' : p.description)
                        : '${p.vendorName}\n${p.description.isEmpty ? '—' : p.description}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${p.price.toStringAsFixed(2)}'),
                      Text(
                        'Stock: ${p.stock}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: qty > 0
                                ? () => _controller.removeFromCart(p)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove',
                          ),
                          Text('$qty'),
                          IconButton(
                            onPressed: () {
                              final message = _controller.addToCart(p);
                              if (message != null && message.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Add',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.load,
                child: buildList(),
              ),
            ),
            if (hasCart)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedAddress == null
                                  ? 'Delivery: Not selected'
                                  : 'Delivery: ${_selectedAddress!.shortSummary}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked =
                                  await Navigator.of(context).push<CustomerAddress>(
                                MaterialPageRoute(
                                  builder: (_) => CustomerAddressesScreen(
                                    apiClient: widget.apiClient,
                                    selectMode: true,
                                  ),
                                ),
                              );

                              if (!mounted) return;
                              if (picked != null) {
                                setState(() => _selectedAddress = picked);
                              }
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Items: ${_controller.cartItemCount}  •  Total: ₹${_controller.cartTotal.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _controller.isLoading
                                ? null
                                : () async {
                                    final address = _selectedAddress;
                                    if (address == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Select a delivery address',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final message =
                                        await _controller.placeOrder(
                                      addressId: address.id,
                                      paymentMethod: 'cod',
                                    );
                                    if (!context.mounted) return;
                                    if (message == null || message.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Order placed'),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    }
                                  },
                            child: const Text('Place order'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: Cash on Delivery',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
