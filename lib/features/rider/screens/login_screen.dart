import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../rider_dependencies.dart';

/// Rider login screen (phone + OTP UI).
///
/// OTP is currently backend-mocked (use `0000`).
class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key, required this.onLoggedIn});

  final VoidCallback onLoggedIn;

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _otpSent = true;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final deps = RiderDependencies.of(context);
      await deps.authService.login(
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onLoggedIn();
    } on AuthExpiredException {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome, Rider', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Login with your phone number. We’ll send an OTP to verify.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. 9876543210',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Enter phone number';
                    if (v.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                      hintText: 'Enter 4–6 digit OTP',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OTP is currently mocked: use 0000.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                if (!_otpSent)
                  FilledButton(
                    onPressed: _submitting ? null : _sendOtp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send OTP'),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _submitting ? null : _verifyOtp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify & Continue'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
