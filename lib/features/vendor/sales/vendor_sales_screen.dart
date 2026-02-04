import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_sales_summary.dart';
import '../services/vendor_sales_service.dart';

class VendorSalesScreen extends StatefulWidget {
  const VendorSalesScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<VendorSalesScreen> createState() => _VendorSalesScreenState();
}

class _VendorSalesScreenState extends State<VendorSalesScreen> {
  late final _Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(service: VendorSalesService(apiClient: widget.apiClient));
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
        title: const Text('Sales'),
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
          if (_controller.loading && _controller.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.error != null && _controller.summary == null) {
            return _ErrorState(message: _controller.error!, onRetry: _controller.load);
          }

          final summary = _controller.summary;
          if (summary == null) {
            return _ErrorState(message: _controller.error ?? 'Failed to load sales summary', onRetry: _controller.load);
          }

          return RefreshIndicator(
            onRefresh: () => _controller.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            label: 'Today Sales',
                            value: '₹${summary.todayTotalSales.toStringAsFixed(2)}',
                          ),
                        ),
                        Expanded(child: _Stat(label: 'Completed', value: '${summary.completedOrdersCount}')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Pending Orders'),
                    subtitle: const Text('Placed / Accepted / Ready'),
                    trailing: Text('${summary.pendingOrdersCount}'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Controller extends ChangeNotifier {
  _Controller({required VendorSalesService service}) : _service = service;

  final VendorSalesService _service;

  bool loading = false;
  String? error;
  VendorSalesSummary? summary;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      summary = await _service.salesSummary(days: 7);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleLarge),
      ],
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
