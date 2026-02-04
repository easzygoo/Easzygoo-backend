/// Central place for backend API configuration.
///
/// Keep this file dependency-free so it can be imported anywhere.
///
/// Configure `baseUrl` at build time via:
/// `--dart-define=API_BASE_URL=https://your-domain.com`
library;

class ApiConstants {
  ApiConstants._();

  /// Base URL of the deployed Django backend.
  ///
  /// Example: `https://api.easzygoo.com`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://easzygoo.onrender.com',
  );

  /// Common API prefix used by the backend.
  static const String apiPrefix = '/api';

  /// Default network timeouts.
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// HTTP headers.
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';

  static const String contentTypeJson = 'application/json';

  /// Returns `Authorization` header value.
  static String bearer(String accessToken) => 'Bearer $accessToken';

  // -----------------
  // Auth
  // -----------------
  static const String authLogin = '$apiPrefix/auth/login/';

  // -----------------
  // Riders
  // -----------------
  static const String ridersMe = '$apiPrefix/riders/me/';
  static const String ridersToggleOnline = '$apiPrefix/riders/toggle-online/';
  static const String ridersUpdateLocation = '$apiPrefix/riders/update-location/';

  // -----------------
  // Orders
  // -----------------
  static const String ordersAssignedActive = '$apiPrefix/orders/assigned-active/';

  /// Path template: `/api/orders/<id>/accept/`
  static String orderAccept(String id) => '$apiPrefix/orders/$id/accept/';

  /// Path template: `/api/orders/<id>/picked/`
  static String orderMarkPicked(String id) => '$apiPrefix/orders/$id/picked/';

  /// Path template: `/api/orders/<id>/delivered/`
  static String orderMarkDelivered(String id) => '$apiPrefix/orders/$id/delivered/';

  static const String ordersEarningsSummary = '$apiPrefix/orders/earnings-summary/';

  // -----------------
  // KYC
  // -----------------
  static const String kycSubmit = '$apiPrefix/kyc/submit/';
  static const String kycStatus = '$apiPrefix/kyc/status/';

  /// Path template: `/api/kyc/view/<document_type>/`
  static String kycViewDocument(String documentType) => '$apiPrefix/kyc/view/$documentType/';
}
