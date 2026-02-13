import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/network/api_client.dart';

import '../home/home_tab.dart';
import '../orders/orders_tab.dart';
import '../profile/profile_tab.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.apiClient,
    required this.onLogout,
  });

  final ApiClient apiClient;

  final Future<void> Function() onLogout;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  final _ordersKey = GlobalKey<CustomerOrdersTabState>();

  @override
  Widget build(BuildContext context) {
    final body = switch (_index) {
      0 => CustomerHomeTab(apiClient: widget.apiClient),
      1 => CustomerOrdersTab(key: _ordersKey, apiClient: widget.apiClient),
      _ => CustomerProfileTab(apiClient: widget.apiClient, onLogout: widget.onLogout),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_index) {
          0 => 'Home',
          1 => 'Orders',
          _ => 'Profile',
        }),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
          if (value == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final state = _ordersKey.currentState;
              if (state == null) return;
              unawaited(state.reload());
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
