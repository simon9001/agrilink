import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/social_feed/social_feed.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/payment_methods/payment_methods.dart';
import '../presentation/veterinary_consultation/veterinary_consultation.dart';
import '../presentation/user_registration/user_registration.dart';
import '../presentation/login/login_screen.dart';

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

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    socialFeed: (context) => const SocialFeed(),
    userProfile: (context) => const UserProfile(),
    paymentMethods: (context) => const PaymentMethods(),
    veterinaryConsultation: (context) => const VeterinaryConsultation(),
    userRegistration: (context) => const UserRegistration(),
    // TODO: Add your other routes here
  };
}
