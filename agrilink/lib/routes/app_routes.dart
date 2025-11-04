import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/social_feed/social_feed.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/payment_methods/payment_methods.dart';
import '../presentation/veterinary_consultation/veterinary_consultation.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/dashboard/farmer_dashboard.dart';
import '../presentation/dashboard/buyer_dashboard.dart';
import '../presentation/dashboard/supplier_dashboard.dart';
import '../presentation/dashboard/expert_dashboard.dart';
import '../presentation/dashboard/admin_dashboard.dart';
import '../core/user_role.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login';
  static const String socialFeed = '/social-feed';
  static const String userProfile = '/user-profile';
  static const String paymentMethods = '/payment-methods';
  static const String veterinaryConsultation = '/veterinary-consultation';
  static const String userRegistration = '/user-registration';

  // Dashboard routes
  static const String dashboard = '/dashboard';
  static const String farmerDashboard = '/dashboard/farmer';
  static const String buyerDashboard = '/dashboard/buyer';
  static const String supplierDashboard = '/dashboard/supplier';
  static const String expertDashboard = '/dashboard/expert';
  static const String adminDashboard = '/dashboard/admin';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    socialFeed: (context) => const SocialFeed(),
    userProfile: (context) => const UserProfile(),
    paymentMethods: (context) => const PaymentMethods(),
    veterinaryConsultation: (context) => const VeterinaryConsultation(),
    userRegistration: (context) => const UserRegistration(),

    // Dashboard routes
    dashboard: (context) => _getDashboardForRole(context),
    farmerDashboard: (context) => const FarmerDashboard(),
    buyerDashboard: (context) => const BuyerDashboard(),
    supplierDashboard: (context) => const SupplierDashboard(),
    expertDashboard: (context) => const ExpertDashboard(),
    adminDashboard: (context) => const AdminDashboard(),

    // TODO: Add your other routes here
  };

  /// Get the appropriate dashboard based on user role
  static Widget _getDashboardForRole(BuildContext context) {
    // For now, we'll use a placeholder role selection
    // In a real app, this would come from authentication state
    final userRole = _getCurrentUserRole(context);

    switch (userRole) {
      case UserRole.FARMER:
        return const FarmerDashboard();
      case UserRole.BUYER:
        return const BuyerDashboard();
      case UserRole.SUPPLIER:
        return const SupplierDashboard();
      case UserRole.EXPERT:
        return const ExpertDashboard();
      case UserRole.ADMIN:
        return const AdminDashboard();
      default:
        return const FarmerDashboard(); // Default fallback
    }
  }

  /// Get dashboard widget for a specific role (for navigation purposes)
  static Widget getDashboardForRole(UserRole? role) {
    switch (role) {
      case UserRole.FARMER:
        return const FarmerDashboard();
      case UserRole.BUYER:
        return const BuyerDashboard();
      case UserRole.SUPPLIER:
        return const SupplierDashboard();
      case UserRole.EXPERT:
        return const ExpertDashboard();
      case UserRole.ADMIN:
        return const AdminDashboard();
      default:
        return const FarmerDashboard();
    }
  }

  /// Get the appropriate dashboard route for a role
  static String getDashboardRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.FARMER:
        return farmerDashboard;
      case UserRole.BUYER:
        return buyerDashboard;
      case UserRole.SUPPLIER:
        return supplierDashboard;
      case UserRole.EXPERT:
        return expertDashboard;
      case UserRole.ADMIN:
        return adminDashboard;
      default:
        return farmerDashboard;
    }
  }

  /// Mock method to get current user role
  /// In a real implementation, this would come from your authentication service
  static UserRole _getCurrentUserRole(BuildContext context) {
    // This is a placeholder - in a real app, you would get this from:
    // - Auth provider state
    // - Shared preferences
    // - API call
    // - etc.

    // For demo purposes, we'll default to Farmer
    // You can change this to test different dashboards
    return UserRole.FARMER;
  }

  /// Navigate to the appropriate dashboard for the current user
  static void navigateToDashboard(BuildContext context) {
    final userRole = _getCurrentUserRole(context);
    final route = getDashboardRouteForRole(userRole);
    Navigator.pushReplacementNamed(context, route);
  }

  /// Navigate to dashboard for a specific role
  static void navigateToRoleDashboard(BuildContext context, UserRole role) {
    final route = getDashboardRouteForRole(role);
    Navigator.pushReplacementNamed(context, route);
  }
}
