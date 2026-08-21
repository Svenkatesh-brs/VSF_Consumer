import 'package:get/get.dart';

import '../providers/loan_dashboard_provider.dart';

class LoanDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanDashboardProvider>(
      () => LoanDashboardProvider(),
    );
  }
}