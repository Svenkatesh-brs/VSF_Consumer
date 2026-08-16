import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/loan_binding.dart';
import '../screens/home_screen.dart';
import '../screens/loan_details_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.loanDetails,
      page: () => const LoanDetailsScreen(),
      binding: LoanBinding(),
    ),
  ];
}