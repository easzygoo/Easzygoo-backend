class VendorApi {
  VendorApi._();

  // Vendors
  static const String vendorsMe = '/api/vendors/me/';
  static const String vendorsToggleOpen = '/api/vendors/toggle-open/';
  static const String vendorsDashboard = '/api/vendors/dashboard/';

  static String vendorsSalesSummary({int days = 7}) => '/api/vendors/sales-summary/?days=$days';

  // Verification
  static const String vendorsVerificationStatus = '/api/vendors/verification/status/';
  static const String vendorsVerificationSubmit = '/api/vendors/verification/submit/';

  // Products
  static const String vendorProducts = '/api/products/';
  static String vendorProduct(String id) => '/api/products/$id/';

  // Orders
  static const String vendorOrders = '/api/orders/vendor/';
  static String vendorOrder(String id) => '/api/orders/vendor/$id/';
  static String vendorOrderAccept(String id) => '/api/orders/vendor/$id/accept/';
  static String vendorOrderReject(String id) => '/api/orders/vendor/$id/reject/';
  static String vendorOrderReady(String id) => '/api/orders/vendor/$id/ready/';
  static String vendorOrderCancel(String id) => '/api/orders/vendor/$id/cancel/';
}
