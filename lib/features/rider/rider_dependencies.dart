import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/kyc_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/rider_service.dart';

/// App-wide dependency scope for the Rider app.
class RiderDependencies extends InheritedWidget {
  const RiderDependencies({
    super.key,
    required super.child,
    required this.apiClient,
    required this.authService,
    required this.riderService,
    required this.orderService,
    required this.kycService,
  });

  final ApiClient apiClient;
  final AuthService authService;
  final RiderService riderService;
  final OrderService orderService;
  final KycService kycService;

  static RiderDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RiderDependencies>();
    assert(scope != null, 'RiderDependencies not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(RiderDependencies oldWidget) => false;
}
