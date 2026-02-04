import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/rider_service.dart';
import '../widgets/order_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.riderService,
    required this.orderService,
    required this.onAuthExpired,
  });

  final RiderService riderService;
  final OrderService orderService;
  final VoidCallback onAuthExpired;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = false;
  RiderProfile? _profile;
  EarningsSummary? _earnings;
  OrderModel? _activeOrder;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.riderService.getProfile();
      final earnings = await widget.orderService.getEarningsSummary();
      final active = await widget.orderService.getActiveOrder();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _earnings = earnings;
        _activeOrder = active;
        _lastUpdated = DateTime.now();
        _loading = false;
      });
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onAuthExpired();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard.')),
      );
    }
  }

  Future<void> _setOnline(bool value) async {
    setState(() => _loading = true);
    try {
      final updated = await widget.riderService.toggleOnline(isOnline: value);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _loading = false;
      });
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onAuthExpired();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update online status.')),
      );
    }

    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = _profile?.isOnline ?? false;
    final totalEarnings = _earnings?.totalDeliveredAmount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline ? 'Ready to accept orders' : 'Go online to receive new orders',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Switch(
                value: isOnline,
                onChanged: _loading ? null : _setOnline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          _EarningsCard(totalEarnings: totalEarnings),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active order', style: theme.textTheme.titleMedium),
              if (_lastUpdated != null)
                Text(
                  'Updated ${_formatTime(_lastUpdated!)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isOnline)
            const _EmptyStateCard(
              icon: Icons.wifi_off,
              title: 'You are offline',
              subtitle: 'Switch online to start receiving orders.',
            )
          else if (_activeOrder != null)
            OrderCard(
              order: _activeOrder!,
              orderService: widget.orderService,
              onAuthExpired: widget.onAuthExpired,
              onOrderUpdated: _loadDashboard,
            )
          else
            _EmptyStateCard(
              icon: Icons.inbox_outlined,
              title: 'No active orders',
              subtitle: 'You’re online. We’ll notify you when an order is assigned.',
              action: OutlinedButton.icon(
                onPressed: _loading ? null : _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.totalEarnings});

  final double totalEarnings;

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
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.payments, color: colorScheme.onTertiaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total earnings', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(_currency(totalEarnings), style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => '₹${value.toStringAsFixed(0)}';

String _formatTime(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// DashboardData and mock service removed; Rider app uses live backend.
