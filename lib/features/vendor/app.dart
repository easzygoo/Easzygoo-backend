import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

import 'dashboard/vendor_dashboard_screen.dart';
import 'orders/vendor_orders_screen.dart';
import 'products/vendor_products_screen.dart';
import 'profile/vendor_profile_screen.dart';
import 'sales/vendor_sales_screen.dart';

/// Vendor app root.
///
/// Note: This file is Vendor-only and does not touch Rider code.
///
/// Next step (after confirmation): wire this into `lib/main_vendor.dart`
/// and move dependencies into a dedicated Vendor dependency scope.
class VendorApp extends StatelessWidget {
  const VendorApp({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaszyGoo Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clamped = mediaQuery.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _VendorRoot(
        apiClient: apiClient,
        authService: authService,
      ),
    );
  }
}

enum _RootState {
  splash,
  unauthenticated,
  authenticated,
}

class _VendorRoot extends StatefulWidget {
  const _VendorRoot({
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  @override
  State<_VendorRoot> createState() => _VendorRootState();
}

class _VendorRootState extends State<_VendorRoot> {
  _RootState _state = _RootState.splash;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final token = await widget.authService.getStoredToken();
    if (!mounted) return;

    setState(() {
      _state = (token != null && token.isNotEmpty) ? _RootState.authenticated : _RootState.unauthenticated;
    });
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (!mounted) return;
    setState(() => _state = _RootState.unauthenticated);
  }

  void _onLoggedIn() {
    setState(() => _state = _RootState.authenticated);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _RootState.splash => const _SplashScreen(),
      _RootState.unauthenticated => VendorLoginScreen(
          authService: widget.authService,
          onLoggedIn: _onLoggedIn,
        ),
      _RootState.authenticated => VendorShell(
          apiClient: widget.apiClient,
          onLogout: _logout,
        ),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({
    super.key,
    required this.authService,
    required this.onLoggedIn,
  });

  final AuthService authService;
  final VoidCallback onLoggedIn;

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
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

    // Backend currently uses mocked OTP; there is no separate "send OTP" endpoint.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _otpSent = true;
    });

    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the OTP')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await widget.authService.login(
        phone: _phoneController.text.trim(),
        otp: otp,
        role: 'vendor',
      );

      final role = (result.user['role'] as String?) ?? '';
      if (role != 'vendor') {
        await widget.authService.logout();
        throw ApiException(message: 'This account is not a vendor');
      }

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
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network timeout. Check internet and API URL: ${ApiConstants.baseUrl}')),
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _submitting = false);
      debugPrint('Vendor login error: $e');
      debugPrintStack(stackTrace: st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(
                  title: 'Welcome, Vendor',
                  subtitle: 'Login with your phone number to manage orders and products.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
                    'OTP is currently mocked by backend: use 0000.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'API: ${ApiConstants.baseUrl}${ApiConstants.authLogin}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                if (!_otpSent)
                  _PrimaryButton(
                    label: 'Send OTP',
                    busy: _submitting,
                    onPressed: _submitting ? null : _sendOtp,
                  )
                else
                  _PrimaryButton(
                    label: 'Verify & Continue',
                    busy: _submitting,
                    onPressed: _submitting ? null : _verifyOtp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VendorShell extends StatefulWidget {
  const VendorShell({
    super.key,
    required this.apiClient,
    required this.onLogout,
  });

  final ApiClient apiClient;

  final Future<void> Function() onLogout;

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      VendorDashboardScreen(apiClient: widget.apiClient),
      VendorProductsScreen(apiClient: widget.apiClient),
      VendorOrdersScreen(apiClient: widget.apiClient),
      VendorSalesScreen(apiClient: widget.apiClient),
      VendorProfileScreen(apiClient: widget.apiClient, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: (_pressed && enabled) ? 0.98 : 1.0,
        child: FilledButton(
          onPressed: enabled ? widget.onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: widget.busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.label),
          ),
        ),
      ),
    );
  }
}
