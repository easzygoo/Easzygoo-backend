import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/rider_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.riderService,
    required this.onAuthExpired,
    required this.onLogout,
  });

  final RiderService riderService;
  final VoidCallback onAuthExpired;

  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = false;
  RiderProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.riderService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
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
        const SnackBar(content: Text('Failed to load profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = _profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rider', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            _InfoRow(label: 'Name', value: (p?.name ?? '—')),
            _InfoRow(label: 'Phone', value: (p?.phone ?? '—')),
            _InfoRow(label: 'Online', value: (p?.isOnline ?? false) ? 'Yes' : 'No'),
            _InfoRow(label: 'KYC', value: (p?.kycStatus.isNotEmpty ?? false) ? p!.kycStatus : '—'),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}
