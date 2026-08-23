import 'package:get/get.dart';

import '../bindings/complaint_binding.dart';
import '../bindings/contact_update_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/loan_dashboard_binding.dart';
import '../screens/complaint_screen.dart';
import '../screens/contact_update_screen.dart';
import '../screens/home_screen.dart';
import '../screens/emi_schedule_screen.dart';
import '../screens/loan_dashboard_screen.dart';
import '../screens/loan_details_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/transactions_screen.dart';
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

    // ==========================================================
    // LOAN DETAILS
    //
    // Reuses the live LoanDashboardProvider and its already
    // fetched loan data. No additional API call.
    // ==========================================================

    GetPage(
      name: AppRoutes.loanDetails,
      page: () => const LoanDetailsScreen(),
    ),

    // ==========================================================
    // TRANSACTIONS
    //
    // Reuses the live LoanDashboardProvider and its already
    // fetched transaction data. No additional API call.
    // ==========================================================

    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsScreen(),
    ),

    // ==========================================================
    // EMI SCHEDULE
    //
    // Reuses the live LoanDashboardProvider and its already
    // fetched EMI schedule data. No additional API call.
    // ==========================================================

    GetPage(
      name: AppRoutes.emiSchedule,
      page: () => const EmiScheduleScreen(),
    ),

    // ==========================================================
    // COMPLAINT
    // ==========================================================

    GetPage(
      name: AppRoutes.complaint,
      page: () => const ComplaintScreen(),
      binding: ComplaintBinding(),
    ),

    // ==========================================================
    // CONTACT UPDATE
    //
    // Reuses the live LoanDashboardProvider and its already
    // fetched address data. No additional API call.
    // ==========================================================

    GetPage(
      name: AppRoutes.contactUpdate,
      page: () => const ContactUpdateScreen(),
      binding: ContactUpdateBinding(),
    ),

  ];
}