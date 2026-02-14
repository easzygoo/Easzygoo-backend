import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'auth/auth_controller.dart';
import 'auth/login_screen.dart';
import 'shell/customer_shell.dart';

class CustomerApp extends StatelessWidget {
  const CustomerApp({
    super.key,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EaszyGoo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clamped = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 2.0,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _CustomerRoot(apiClient: apiClient, authService: authService),
    );
  }
}

class _CustomerRoot extends StatefulWidget {
  const _CustomerRoot({required this.apiClient, required this.authService});

  final ApiClient apiClient;
  final AuthService authService;

  @override
  State<_CustomerRoot> createState() => _CustomerRootState();
}

class _CustomerRootState extends State<_CustomerRoot> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController(authService: widget.authService);
    unawaited(() async {
      try {
        await _auth.boot().timeout(const Duration(seconds: 8));
      } catch (e) {
        _auth.setBootError(e);
      }
    }());
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        return switch (_auth.status) {
          AuthStatus.splash => const _SplashScreen(),
          AuthStatus.unauthenticated => CustomerLoginScreen(controller: _auth),
          AuthStatus.authenticated => CustomerShell(
            apiClient: widget.apiClient,
            onLogout: _auth.logout,
          ),
        };
      },
    );
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
