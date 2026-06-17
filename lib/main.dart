import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/colors.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/api_users_screen.dart';
import 'screens/network_posts_screen.dart';
import 'screens/customer_visits_screen.dart';
import 'screens/customer_visit_report_screen.dart';
import 'models/product.dart';
import 'models/cart_item.dart';

void main() {
  // Set the status bar style for a polished look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FreshMartApp());
}

class FreshMartApp extends StatelessWidget {
  const FreshMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
        ),
      ),

      // ── Routes ─────────────────────────────────────────────
      initialRoute: AppConstants.routeSplash,
      routes: {
        AppConstants.routeSplash: (context) => const SplashScreen(),
        AppConstants.routeLogin: (context) => const LoginScreen(),
        AppConstants.routeRegister: (context) => const RegisterScreen(),
        AppConstants.routeHome: (context) => const HomeScreen(),
        AppConstants.routeCart: (context) {
          final cart = ModalRoute.of(context)!.settings.arguments
              as List<CartItem>? ?? [];
          return CartScreen(cartItems: cart);
        },
        AppConstants.routeOrderConfirmation: (context) =>
            const OrderConfirmationScreen(),
        AppConstants.routeProfile: (context) => const ProfileScreen(),
        AppConstants.routeCustomers: (context) => const CustomersScreen(),
        AppConstants.routeApiUsers: (context) => const ApiUsersScreen(),
        AppConstants.routeNetworkPosts: (context) => const NetworkPostsScreen(),
        AppConstants.routeCustomerVisits: (context) => const CustomerVisitsScreen(),
        AppConstants.routeCustomerVisitReport: (context) => const CustomerVisitReportScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppConstants.routeProductDetail) {
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          );
        }
        return null;
      },
    );
  }
}
