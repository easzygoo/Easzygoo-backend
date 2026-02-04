import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/kyc_model.dart';
import '../../services/kyc_controller.dart';

class KycFormScreen extends StatefulWidget {
  const KycFormScreen({
    super.key,
    required this.controller,
    this.onSubmitted,
  });

  final KycController controller;

  /// Called after a successful submit (status becomes pending).
  final VoidCallback? onSubmitted;

  @override
  State<KycFormScreen> createState() => _KycFormScreenState();
}

class _KycFormScreenState extends State<KycFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  final _picker = ImagePicker();
  final Map<KycDocumentType, XFile> _picked = {};

  bool _submittedCallbackFired = false;

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  bool get _hasAllDocs => _picked.length == KycDocumentType.values.length;

  Future<void> _pick(KycDocumentType type) async {
    final source = await _selectSource(type);
    if (source == null) return;

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() {
      _picked[type] = file;
    });
  }

  Future<ImageSource?> _selectSource(KycDocumentType type) async {
    // For selfie, camera is most common. For docs, gallery is typical.
    final defaultSource = (type == KycDocumentType.selfie) ? ImageSource.camera : ImageSource.gallery;

    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Default: ${defaultSource == ImageSource.camera ? 'Camera' : 'Gallery'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (!_hasAllDocs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload all required documents.')),
      );
      return;
    }

    final submission = KycSubmission(
      documents: {
        for (final entry in _picked.entries)
          entry.key: KycDocument(type: entry.key, localPath: entry.value.path),
      },
      bankAccountNumber: _accountController.text.trim(),
      ifscCode: _ifscController.text.trim().toUpperCase(),
    );

    await widget.controller.submit(submission);

    if (!mounted) return;

    final err = widget.controller.errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    if (widget.controller.status == KycStatus.pending && !_submittedCallbackFired) {
      _submittedCallbackFired = true;
      widget.onSubmitted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final loading = widget.controller.isLoading;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('KYC Verification'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Upload documents', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Complete KYC to start accepting orders.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...KycDocumentType.values.map(
                (type) => _DocTile(
                  label: type.label,
                  selectedName: _picked[type]?.name,
                  onPick: loading ? null : () => _pick(type),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Bank details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bank account number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Enter bank account number';
                        if (!KycValidators.isValidAccountNumber(v)) return 'Enter a valid account number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ifscController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IFSC code',
                        hintText: 'e.g. HDFC0001234',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Enter IFSC code';
                        if (!KycValidators.isValidIfsc(v)) return 'Enter a valid IFSC code';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (loading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.label,
    required this.selectedName,
    required this.onPick,
  });

  final String label;
  final String? selectedName;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = (selectedName ?? '').trim().isNotEmpty;

    return Card(
      child: ListTile(
        leading: Icon(picked ? Icons.check_circle : Icons.upload_file),
        title: Text(label),
        subtitle: picked
            ? Text(
                selectedName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text('Not uploaded', style: theme.textTheme.bodySmall),
        trailing: TextButton(
          onPressed: onPick,
          child: Text(picked ? 'Change' : 'Upload'),
        ),
      ),
    );
  }
}
