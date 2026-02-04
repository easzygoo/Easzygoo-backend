import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_profile.dart';
import '../services/vendor_profile_service.dart';
import '../verification/vendor_verification_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({
    super.key,
    required this.apiClient,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final Future<void> Function() onLogout;

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  late final _Controller _controller;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(service: VendorProfileService(apiClient: widget.apiClient));
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
        title: const Text('Profile'),
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
          if (_controller.loading && _controller.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null && _controller.profile == null) {
            return _ErrorState(message: _controller.error!, onRetry: _controller.load);
          }

          final p = _controller.profile;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (p != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(p.shopName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(p.address),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.isOpen ? 'Shop is OPEN' : 'Shop is CLOSED'),
                          value: p.isOpen,
                          onChanged: _controller.toggling
                              ? null
                              : (_) async {
                                  if (!context.mounted) return;
                                  final messenger = ScaffoldMessenger.of(context);
                                  final newValue = await _controller.toggle();
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(newValue ? 'Shop opened' : 'Shop closed')),
                                  );
                                },
                        ),
                        if (_controller.toggling) const LinearProgressIndicator(minHeight: 2),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Account', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await widget.onLogout();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Verification'),
                        subtitle: const Text('Upload documents for approval'),
                        onTap: _controller.loading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VendorVerificationScreen(apiClient: widget.apiClient),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Controller extends ChangeNotifier {
  _Controller({required VendorProfileService service}) : _service = service;

  final VendorProfileService _service;

  bool loading = false;
  bool toggling = false;
  String? error;
  VendorProfile? profile;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _service.fetchProfile();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle() async {
    toggling = true;
    error = null;
    notifyListeners();

    try {
      final isOpen = await _service.toggleOpen();
      final current = profile;
      if (current != null) {
        profile = VendorProfile(
          id: current.id,
          shopName: current.shopName,
          address: current.address,
          latitude: current.latitude,
          longitude: current.longitude,
          isOpen: isOpen,
        );
      }
      return isOpen;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      toggling = false;
      notifyListeners();
    }
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
