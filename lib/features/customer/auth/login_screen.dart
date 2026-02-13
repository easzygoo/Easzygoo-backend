import 'package:flutter/material.dart';

import 'auth_controller.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _sendingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sendingOtp = true);

    // Backend currently uses mocked OTP; there is no separate "send OTP" endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    setState(() {
      _sendingOtp = false;
      _otpSent = true;
    });

    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the OTP')));
      return;
    }

    final errorMessage = await widget.controller.login(
      phone: _phoneController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;

    if (errorMessage != null && errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final busy = widget.controller.isBusy || _sendingOtp;

        return Scaffold(
          appBar: AppBar(title: const Text('EaszyGoo')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Customer Login',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: 'e.g. 9876543210',
                      ),
                      enabled: !busy,
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) return 'Enter phone number';
                        if (v.length < 8) return 'Enter valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_otpSent)
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'OTP',
                          hintText: '4 digits',
                        ),
                        enabled: !busy,
                        onFieldSubmitted: (_) => busy ? null : _verifyOtp(),
                      ),
                    const Spacer(),
                    if (!_otpSent)
                      FilledButton(
                        onPressed: busy ? null : _sendOtp,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send OTP'),
                      )
                    else
                      FilledButton(
                        onPressed: busy ? null : _verifyOtp,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Login'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
