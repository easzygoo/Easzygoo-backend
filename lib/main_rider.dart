import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/kyc_service.dart';
import 'core/services/order_service.dart';
import 'core/services/rider_service.dart';
import 'features/rider/app.dart';
import 'features/rider/rider_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rider apps typically run portrait-only.
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // TODO: hook crash reporting when backend/infrastructure is ready.
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (!kReleaseMode) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };

  runZonedGuarded(
    () => runApp(const RiderBootstrap()),
    (Object error, StackTrace stack) {
      if (!kReleaseMode) {
        debugPrint('runZonedGuarded error: $error');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}

/// App bootstrap wrapper.
///
/// This is the right place to initialize mock services, app config, and
/// dependency injection (kept lightweight for now).
class RiderBootstrap extends StatelessWidget {
  const RiderBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RiderBootstrapScope(child: RiderApp());
  }
}

class _RiderBootstrapScope extends StatefulWidget {
  const _RiderBootstrapScope({required this.child});

  final Widget child;

  @override
  State<_RiderBootstrapScope> createState() => _RiderBootstrapScopeState();
}

class _RiderBootstrapScopeState extends State<_RiderBootstrapScope> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final RiderService _riderService;
  late final OrderService _orderService;
  late final KycService _kycService;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authService = AuthService(apiClient: _apiClient);
    _riderService = RiderService(apiClient: _apiClient);
    _orderService = OrderService(apiClient: _apiClient);
    _kycService = KycService(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiderDependencies(
      apiClient: _apiClient,
      authService: _authService,
      riderService: _riderService,
      orderService: _orderService,
      kycService: _kycService,
      child: widget.child,
    );
  }
}

// RiderDependencies is defined in `lib/features/rider/rider_dependencies.dart`.
