import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/vendor_verification_status.dart';
import '../services/vendor_verification_service.dart';

class VendorVerificationScreen extends StatefulWidget {
  const VendorVerificationScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<VendorVerificationScreen> createState() => _VendorVerificationScreenState();
}

class _VendorVerificationScreenState extends State<VendorVerificationScreen> {
  late final VendorVerificationService _service;
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String? _error;
  VendorVerificationStatus? _status;

  XFile? _idFront;
  XFile? _idBack;
  XFile? _shopLicense;
  XFile? _selfie;

  @override
  void initState() {
    super.initState();
    _service = VendorVerificationService(apiClient: widget.apiClient);
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final s = await _service.status();
      if (mounted) {
        setState(() => _status = s);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pick(String which) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (!mounted) return;
    if (file == null) return;

    setState(() {
      switch (which) {
        case 'idFront':
          _idFront = file;
          break;
        case 'idBack':
          _idBack = file;
          break;
        case 'shopLicense':
          _shopLicense = file;
          break;
        case 'selfie':
          _selfie = file;
          break;
      }
    });
  }

  bool get _canSubmit => _idFront != null && _idBack != null && _shopLicense != null && _selfie != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final idFront = await http.MultipartFile.fromPath('id_front', _idFront!.path);
      final idBack = await http.MultipartFile.fromPath('id_back', _idBack!.path);
      final shopLicense = await http.MultipartFile.fromPath('shop_license', _shopLicense!.path);
      final selfie = await http.MultipartFile.fromPath('selfie', _selfie!.path);

      await _service.submit(
        idFront: idFront,
        idBack: idBack,
        shopLicense: shopLicense,
        selfie: selfie,
      );

      await _loadStatus();

      messenger.showSnackBar(const SnackBar(content: Text('Verification submitted')));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current status', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_loading && _status == null) const LinearProgressIndicator(),
                  if (_error != null) ...[
                    Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _status == null
                        ? '—'
                        : (_status!.submitted ? (_status!.status ?? 'pending') : 'not submitted'),
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PickTile(
            label: 'ID Front (JPEG)',
            file: _idFront,
            onPick: _loading ? null : () => _pick('idFront'),
          ),
          _PickTile(
            label: 'ID Back (JPEG)',
            file: _idBack,
            onPick: _loading ? null : () => _pick('idBack'),
          ),
          _PickTile(
            label: 'Shop License (JPEG)',
            file: _shopLicense,
            onPick: _loading ? null : () => _pick('shopLicense'),
          ),
          _PickTile(
            label: 'Selfie (JPEG)',
            file: _selfie,
            onPick: _loading ? null : () => _pick('selfie'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_loading || !_canSubmit) ? null : _submit,
            child: _loading ? const Text('Submitting...') : const Text('Submit for Verification'),
          ),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.label,
    required this.file,
    required this.onPick,
  });

  final String label;
  final XFile? file;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(file == null ? 'Not selected' : file!.name),
        trailing: TextButton(
          onPressed: onPick,
          child: const Text('Choose'),
        ),
        onTap: onPick,
        leading: file == null
            ? const Icon(Icons.insert_drive_file_outlined)
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(file!.path),
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}
