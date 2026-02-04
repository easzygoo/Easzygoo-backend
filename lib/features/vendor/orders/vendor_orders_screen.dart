import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_order.dart';
import '../services/vendor_orders_service.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  late final _Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(service: VendorOrdersService(apiClient: widget.apiClient));
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          _StatusFilter(
            value: _controller.status,
            onChanged: _controller.loading
                ? null
                : (v) {
                    _controller.setStatus(v);
                    _controller.load();
                  },
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.loading ? null : _controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.loading && _controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.orders.isEmpty) {
            return _ErrorState(message: _controller.error!, onRetry: _controller.load);
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = _controller.orders[index];
                final busy = _controller.busyIds.contains(o.id);
                return _OrderCard(
                  order: o,
                  busy: busy,
                  onAccept: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.accept(o.id);
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Order accepted')));
                  },
                  onReject: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reject order?'),
                        content: const Text('This will reject/cancel the order.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, reject')),
                        ],
                      ),
                    );
                    if (ok != true) return;

                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.reject(o.id);
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Order rejected')));
                  },
                  onReady: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.markReady(o.id);
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Marked as READY')));
                  },
                  onCancel: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel order?'),
                        content: const Text('This will mark the order as CANCELLED.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, cancel')),
                        ],
                      ),
                    );
                    if (ok != true) return;

                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    await _controller.cancel(o.id);
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('Order cancelled')));
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Controller extends ChangeNotifier {
  _Controller({required VendorOrdersService service}) : _service = service;

  final VendorOrdersService _service;

  bool loading = false;
  String? error;
  String? status;
  List<VendorOrder> orders = <VendorOrder>[];
  final Set<String> busyIds = <String>{};

  void setStatus(String? s) {
    status = (s == null || s.isEmpty) ? null : s;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      orders = await _service.listOrders(status: status);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markReady(String id) async {
    busyIds.add(id);
    notifyListeners();
    try {
      await _service.markReady(id);
      orders = await _service.listOrders(status: status);
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> cancel(String id) async {
    busyIds.add(id);
    notifyListeners();
    try {
      await _service.cancel(id);
      orders = await _service.listOrders(status: status);
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> accept(String id) async {
    busyIds.add(id);
    notifyListeners();
    try {
      await _service.accept(id);
      orders = await _service.listOrders(status: status);
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> reject(String id) async {
    busyIds.add(id);
    notifyListeners();
    try {
      await _service.reject(id);
      orders = await _service.listOrders(status: status);
    } catch (e) {
      error = e.toString();
    } finally {
      busyIds.remove(id);
      notifyListeners();
    }
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const <String?>[null, 'placed', 'accepted', 'ready', 'picked', 'delivered', 'cancelled'];

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          onChanged: onChanged,
          items: items
              .map(
                (s) => DropdownMenuItem<String?>(
                  value: s,
                  child: Text(s ?? 'All'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onReady,
    required this.onCancel,
  });

  final VendorOrder order;
  final bool busy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;
  final Future<void> Function() onReady;
  final Future<void> Function() onCancel;

  bool get _canAccept => order.status == 'placed';
  bool get _canReject => !{'picked', 'delivered', 'cancelled'}.contains(order.status);
  bool get _canMarkReady => order.status == 'placed' || order.status == 'accepted';
  bool get _canCancel => !{'picked', 'delivered', 'cancelled'}.contains(order.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ${order.id.substring(0, order.id.length.clamp(8, 999))}',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Items: ${order.items.length}  •  Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            if (order.createdAt != null)
              Text(
                'Created: ${order.createdAt!.toLocal()}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (busy || !_canAccept) ? null : () => onAccept(),
                    icon: const Icon(Icons.thumb_up_alt_outlined),
                    label: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (busy || !_canReject) ? null : () => onReject(),
                    icon: const Icon(Icons.thumb_down_alt_outlined),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (busy || !_canMarkReady) ? null : () => onReady(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Ready'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (busy || !_canCancel) ? null : () => onCancel(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;

    switch (status) {
      case 'ready':
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        break;
      case 'picked':
      case 'delivered':
        bg = cs.secondaryContainer;
        fg = cs.onSecondaryContainer;
        break;
      case 'cancelled':
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
