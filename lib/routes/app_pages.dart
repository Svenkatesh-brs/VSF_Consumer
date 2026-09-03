import 'package:get/get.dart';

import '../screens/pay_emi_screen.dart';
import '../bindings/complaint_binding.dart';
import '../bindings/contact_update_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/loan_dashboard_binding.dart';
import '../screens/complaint_screen.dart';
import '../screens/contact_update_screen.dart';
import '../screens/home_screen.dart';
import '../screens/emi_schedule_screen.dart';
import '../screens/help_screen.dart';
import '../screens/loan_dashboard_screen.dart';
import '../screens/loan_details_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/receipt_preview_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/transactions_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    // ==========================================================
    // SPLASH
    // ==========================================================

    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),

    // ==========================================================
    // LOGIN
    // ==========================================================
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),

    // ==========================================================
    // OTP
    // ==========================================================
    GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),

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
    GetPage(name: AppRoutes.loanDetails, page: () => const LoanDetailsScreen()),

    // ==========================================================
    // TRANSACTIONS
    //
    // Reuses LoanDashboardProvider and its transaction data.
    // The binding is required because this screen can also be
    // opened directly from a notification.
    // ==========================================================
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsScreen(),
      binding: LoanDashboardBinding(),
    ),
    // ==========================================================
    // RECEIPT PREVIEW
    //
    // Receives the tapped merged LoanTransaction through
    // navigation arguments and reuses the live
    // LoanDashboardProvider for loan/customer context.
    // No additional API call.
    // ==========================================================
    GetPage(
      name: AppRoutes.receiptPreview,
      page: () => const ReceiptPreviewScreen(),
    ),

    // ==========================================================
    // EMI SCHEDULE
    //
    // Reuses LoanDashboardProvider and its EMI schedule data.
    // The binding is required because this screen can also be
    // opened directly from a notification.
    // ==========================================================
    GetPage(
      name: AppRoutes.emiSchedule,
      page: () => const EmiScheduleScreen(),
      binding: LoanDashboardBinding(),
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

    // ==========================================================
    // HELP & SUPPORT
    //
    // Purely informational screen. Offers Call / WhatsApp
    // support via url_launcher. No API call.
    // ==========================================================
    GetPage(name: AppRoutes.help, page: () => const HelpScreen()),

    //    // ==========================================================
    //    // PAY EMI
    //    // Reuses the live LoanDashboardProvider and its already
    //    // fetched EMI schedule data. No additional API call.
    //    // ==========================================================
    GetPage(name: AppRoutes.payEmi, page: () => const PayEmiScreen()),
  ];
}
