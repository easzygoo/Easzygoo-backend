import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_service.dart';
import 'features/vendor/app.dart' as vendor_app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

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

  runZonedGuarded(
    () => runApp(const VendorBootstrap()),
    (Object error, StackTrace stack) {
      if (!kReleaseMode) {
        debugPrint('runZonedGuarded error: $error');
        debugPrintStack(stackTrace: stack);
      }
    },
  );
}

/// Vendor app bootstrap wrapper.
///
/// Keeps Vendor code isolated. No Rider code is touched.
class VendorBootstrap extends StatefulWidget {
  const VendorBootstrap({super.key});

  @override
  State<VendorBootstrap> createState() => _VendorBootstrapState();
}

class _VendorBootstrapState extends State<VendorBootstrap> {
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
    return VendorDependencies(
      apiClient: _apiClient,
      authService: _authService,
      child: vendor_app.VendorApp(
        apiClient: _apiClient,
        authService: _authService,
      ),
    );
  }
}

/// Vendor dependency scope.
///
/// We’ll expand this as we add Vendor controllers/services (dashboard/products/orders).
class VendorDependencies extends InheritedWidget {
  const VendorDependencies({
    super.key,
    required super.child,
    required this.apiClient,
    required this.authService,
  });

  final ApiClient apiClient;
  final AuthService authService;

  static VendorDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<VendorDependencies>();
    assert(scope != null, 'VendorDependencies not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(VendorDependencies oldWidget) => false;
}
