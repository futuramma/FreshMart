/// FreshMart App Constants
/// Shared values used throughout the application
class AppConstants {
  // App info
  static const String appName = 'FreshMart';
  static const String appTagline = 'Fresh Groceries Delivered to You';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyCustomerEmail = 'customer_email';
  static const String keyCustomerName = 'customer_name';
  static const String keyCustomerId = 'customer_id';

  // Database
  static const String dbName = 'freshmart.db';
  static const int dbVersion = 1;

  // Table names
  static const String tableCustomers = 'customers';
  static const String tableProducts = 'products';
  static const String tableOrders = 'orders';
  static const String tablePostsCache = 'posts_cache';
  static const String tableCustomerVisits = 'customer_visits';

  // Networking
  static const String apiUsersUrl =
      'https://jsonplaceholder.typicode.com/users';
  static const String apiPostsUrl =
      'https://jsonplaceholder.typicode.com/posts';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeProductDetail = '/product-detail';
  static const String routeCart = '/cart';
  static const String routeOrderConfirmation = '/order-confirmation';
  static const String routeProfile = '/profile';
  static const String routeCustomers = '/customers';
  static const String routeApiUsers = '/api-users';
  static const String routeNetworkPosts = '/network-posts';
  static const String routeCustomerVisits = '/customer-visits';
  static const String routeCustomerVisitReport = '/customer-visit-report';

  // UI dimensions
  static const double borderRadius = 16.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 24.0;
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(seconds: 3);
}
