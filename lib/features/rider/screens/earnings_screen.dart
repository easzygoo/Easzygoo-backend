import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({
    super.key,
    required this.orderService,
    required this.onAuthExpired,
  });

  final OrderService orderService;
  final VoidCallback onAuthExpired;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _loading = false;
  EarningsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await widget.orderService.getEarningsSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onAuthExpired();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load earnings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deliveredOrders = _summary?.deliveredOrders ?? 0;
    final totalAmount = _summary?.totalDeliveredAmount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          _SummaryHeader(
            totalEarnings: totalAmount,
            completedOrders: deliveredOrders,
          ),
          const SizedBox(height: 24),
          Text(
            'Note: earnings summary is currently overall delivered totals.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalEarnings,
    required this.completedOrders,
  });

  final double totalEarnings;
  final int completedOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total delivered amount',
                value: _currency(totalEarnings),
                icon: Icons.payments,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Completed orders',
                value: completedOrders.toString(),
                icon: Icons.task_alt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => '₹${value.toStringAsFixed(0)}';
