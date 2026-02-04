import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/earnings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/kyc/kyc_form_screen.dart';
import 'screens/kyc/kyc_pending_screen.dart';
import 'screens/kyc/kyc_rejected_screen.dart';

import 'models/kyc_model.dart';
import 'services/kyc_controller.dart';
import 'rider_dependencies.dart';

/// Rider app root widget. All rider UI is scoped under this app.
///
/// Frontend-only for now (mock services will be wired later).
class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaszyGoo Rider',
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
      home: const RiderRoot(),
    );
  }
}

enum _RootState {
  splash,
  unauthenticated,
  kycChecking,
  kycForm,
  kycPending,
  kycRejected,
  authenticated,
}

/// App root state machine:
/// Splash -> Login -> App shell.
class RiderRoot extends StatefulWidget {
  const RiderRoot({super.key});

  @override
  State<RiderRoot> createState() => _RiderRootState();
}

class _RiderRootState extends State<RiderRoot> {
  _RootState _state = _RootState.splash;

  bool _initialized = false;
  KycController? _kycController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final deps = RiderDependencies.of(context);
    _kycController = KycController(
      service: deps.kycService,
      onAuthExpired: _onAuthExpired,
    );
    _boot();
  }

  @override
  void dispose() {
    _kycController?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    // Simulate local boot: preloading fonts/theme, reading cached session etc.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final deps = RiderDependencies.of(context);
    final token = await deps.authService.getStoredToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      setState(() => _state = _RootState.kycChecking);
      unawaited(_resolvePostLogin());
    } else {
      setState(() => _state = _RootState.unauthenticated);
    }
  }

  void _onLoggedIn() {
    setState(() => _state = _RootState.kycChecking);
    unawaited(_resolvePostLogin());
  }

  Future<void> _resolvePostLogin() async {
    final controller = _kycController;
    if (controller == null) return;
    await controller.load();
    if (!mounted) return;
    _routeFromKyc();
  }

  void _routeFromKyc() {
    final controller = _kycController;
    if (controller == null) return;
    final status = controller.status;

    if (!controller.hasSubmission) {
      setState(() => _state = _RootState.kycForm);
      return;
    }

    switch (status) {
      case null:
        setState(() => _state = _RootState.kycForm);
      case KycStatus.pending:
        setState(() => _state = _RootState.kycPending);
      case KycStatus.rejected:
        setState(() => _state = _RootState.kycRejected);
      case KycStatus.approved:
        setState(() => _state = _RootState.authenticated);
    }
  }

  void _onLogout() {
    final deps = RiderDependencies.of(context);
    unawaited(deps.authService.logout());
    setState(() => _state = _RootState.unauthenticated);
    final controller = _kycController;
    if (controller != null) {
      unawaited(controller.reset());
    }
  }

  void _onAuthExpired() {
    if (!mounted) return;
    _onLogout();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _RootState.splash:
        return const RiderSplashScreen();
      case _RootState.unauthenticated:
        return RiderLoginScreen(onLoggedIn: _onLoggedIn);
      case _RootState.kycChecking:
        return const _KycLoadingScreen();
      case _RootState.kycForm:
        return KycFormScreen(
          controller: _kycController!,
          onSubmitted: () {
            setState(() => _state = _RootState.kycPending);
          },
        );
      case _RootState.kycPending:
        return KycPendingScreen(
          controller: _kycController!,
          onApproved: () {
            setState(() => _state = _RootState.authenticated);
          },
          onRejected: () {
            setState(() => _state = _RootState.kycRejected);
          },
        );
      case _RootState.kycRejected:
        return KycRejectedScreen(
          controller: _kycController!,
          onResubmit: () {
            setState(() => _state = _RootState.kycForm);
          },
          onApproved: () {
            setState(() => _state = _RootState.authenticated);
          },
        );
      case _RootState.authenticated:
        return RiderAppShell(onLogout: _onLogout);
    }
  }
}

class _KycLoadingScreen extends StatelessWidget {
  const _KycLoadingScreen();

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

/// Bottom-tab shell for Rider.
class RiderAppShell extends StatefulWidget {
  const RiderAppShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<RiderAppShell> createState() => _RiderAppShellState();
}

class _RiderAppShellState extends State<RiderAppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final deps = RiderDependencies.of(context);
    final pages = <Widget>[
      DashboardScreen(
        riderService: deps.riderService,
        orderService: deps.orderService,
        onAuthExpired: widget.onLogout,
      ),
      EarningsScreen(
        orderService: deps.orderService,
        onAuthExpired: widget.onLogout,
      ),
      ProfileScreen(
        riderService: deps.riderService,
        onAuthExpired: widget.onLogout,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

