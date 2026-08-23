import 'package:get/get.dart';

import '../providers/loan_dashboard_provider.dart';
import '../services/api_service.dart';
import '../services/loan_dashboard_service.dart';

class LoanDashboardBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // LOAN DASHBOARD SERVICE
    //
    // Reuses the single ApiService registered in AppBinding.
    // ============================================================

    Get.lazyPut<LoanDashboardService>(
      () => LoanDashboardService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    // ============================================================
    // LOAN DASHBOARD PROVIDER
    // ============================================================

    Get.lazyPut<LoanDashboardProvider>(
      () => LoanDashboardProvider(),
      fenix: true,
    );
  }
}
