import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'address_form_screen.dart';
import 'controllers/customer_addresses_controller.dart';
import 'models/customer_address.dart';
import 'services/customer_address_service.dart';

class CustomerAddressesScreen extends StatefulWidget {
  const CustomerAddressesScreen({
    super.key,
    required this.apiClient,
    this.selectMode = false,
  });

  final ApiClient apiClient;
  final bool selectMode;

  @override
  State<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends State<CustomerAddressesScreen> {
  late final CustomerAddressService _service;
  late final CustomerAddressesController _controller;

  @override
  void initState() {
    super.initState();
    _service = CustomerAddressService(apiClient: widget.apiClient);
    _controller = CustomerAddressesController(addressService: _service);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<CustomerAddress>(
      MaterialPageRoute(
        builder: (_) => CustomerAddressFormScreen(addressService: _service),
      ),
    );
    if (saved != null) {
      await _controller.load();
    }
  }

  Future<void> _edit(CustomerAddress address) async {
    final saved = await Navigator.of(context).push<CustomerAddress>(
      MaterialPageRoute(
        builder: (_) => CustomerAddressFormScreen(
          addressService: _service,
          initial: address,
        ),
      ),
    );
    if (saved != null) {
      await _controller.load();
    }
  }

  Future<void> _confirmDelete(CustomerAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(address.shortSummary),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _controller.delete(address.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Select address' : 'Addresses'),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add),
            tooltip: 'Add',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final items = _controller.items;
          final error = _controller.error;
          final isLoading = _controller.isLoading;

          Widget buildList() {
            if ((error != null && error.isNotEmpty) && items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    'Failed to load addresses\n$error\n\nPull to refresh.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            if (items.isEmpty) {
              if (isLoading) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No addresses yet\nTap + to add one.')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = items[index];

                return Card(
                  child: ListTile(
                    title: Text(a.label.isEmpty ? 'Address' : a.label),
                    subtitle: Text(
                      '${a.line1}${a.city.isNotEmpty ? '\n${a.city}, ${a.state} ${a.pincode}' : ''}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: a.isDefault
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.location_on_outlined),
                    onTap: widget.selectMode
                        ? () => Navigator.of(context).pop(a)
                        : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final messenger = ScaffoldMessenger.of(this.context);
                        if (value == 'default') {
                          try {
                            await _controller.makeDefault(a.id);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        } else if (value == 'edit') {
                          await _edit(a);
                        } else if (value == 'delete') {
                          await _confirmDelete(a);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set default'),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
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
      ),
    );
  }
}
