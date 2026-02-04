import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_dashboard.dart';
import '../services/vendor_dashboard_service.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late final _Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(service: VendorDashboardService(apiClient: widget.apiClient));
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
        title: const Text('Dashboard'),
        actions: [
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
          if (_controller.loading && _controller.dashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null && _controller.dashboard == null) {
            return _ErrorState(message: _controller.error!, onRetry: _controller.load);
          }

          final d = _controller.dashboard;
          if (d == null) {
            return _ErrorState(message: 'No data', onRetry: _controller.load);
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          d.shopName.isEmpty ? 'Vendor' : d.shopName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(d.isOpen ? 'Shop is OPEN' : 'Shop is CLOSED'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Today Orders', value: '${d.todayOrders}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Today Revenue', value: '₹${d.todayRevenue.toStringAsFixed(2)}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Placed', value: '${d.placedOrders}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Accepted', value: '${d.acceptedOrders}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Ready', value: '${d.readyOrders}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Picked', value: '${d.pickedOrders}')),
                  ],
                ),
                if (_controller.error != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(text: _controller.error!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Controller extends ChangeNotifier {
  _Controller({required VendorDashboardService service}) : _service = service;

  final VendorDashboardService _service;

  bool loading = false;
  String? error;
  VendorDashboard? dashboard;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      dashboard = await _service.fetchDashboard();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: cs.onErrorContainer)),
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
