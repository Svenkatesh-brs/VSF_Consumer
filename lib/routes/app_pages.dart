import 'package:get/get.dart';

import '../bindings/home_binding.dart';
import '../bindings/loan_dashboard_binding.dart';
import '../screens/home_screen.dart';
import '../screens/loan_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    // ==========================================================
    // SPLASH
    // ==========================================================

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    // ==========================================================
    // LOGIN
    // ==========================================================

    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),

    // ==========================================================
    // OTP
    // ==========================================================

    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
    ),

    // ==========================================================
    // HOME
    // ==========================================================

    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),

    // ==========================================================
    // LOAN DASHBOARD
    // ==========================================================

    GetPage(
      name: AppRoutes.loanDashboard,
      page: () => const LoanDashboardScreen(),
      binding: LoanDashboardBinding(),
    ),
  ];
}