import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../addresses/addresses_screen.dart';
import 'controllers/customer_profile_controller.dart';
import 'services/customer_profile_service.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({
    super.key,
    required this.apiClient,
    required this.onLogout,
  });

  final ApiClient apiClient;

  final Future<void> Function() onLogout;

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  late final CustomerProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CustomerProfileController(
      profileService: CustomerProfileService(apiClient: widget.apiClient),
    );
    _controller.load();
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
        final me = _controller.me;
        final error = _controller.error;

        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (_controller.isLoading && me == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else if (error != null && error.isNotEmpty && me == null)
                Text('Failed to load profile\n$error')
              else if (me != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.name.isEmpty ? 'Customer' : me.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Phone: ${me.phone}'),
                        Text('Role: ${me.role}'),
                        Text('Joined: ${me.createdAt}'),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerAddressesScreen(
                        apiClient: widget.apiClient,
                      ),
                    ),
                  );
                },
                child: const Text('Addresses'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  await widget.onLogout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}
