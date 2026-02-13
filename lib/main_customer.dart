import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'features/customer/app.dart' as customer_app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // Hook crash reporting later.
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (!kReleaseMode) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };

  runZonedGuarded(() => runApp(const CustomerBootstrap()), (
    Object error,
    StackTrace stack,
  ) {
    if (!kReleaseMode) {
      debugPrint('runZonedGuarded error: $error');
      debugPrintStack(stackTrace: stack);
    }
  });
}

class CustomerBootstrap extends StatefulWidget {
  const CustomerBootstrap({super.key});

  @override
  State<CustomerBootstrap> createState() => _CustomerBootstrapState();
}

class _CustomerBootstrapState extends State<CustomerBootstrap> {
  late final ApiClient _apiClient;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authService = AuthService(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomerDependencies(
      apiClient: _apiClient,
      authService: _authService,
      child: customer_app.CustomerApp(
        apiClient: _apiClient,
        authService: _authService,
      ),
    );
  }
}

class CustomerDependencies extends InheritedWidget {
  const CustomerDependencies({
    super.key,
    required super.child,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  static CustomerDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CustomerDependencies>();
    assert(scope != null, 'CustomerDependencies not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(CustomerDependencies oldWidget) => false;
}
