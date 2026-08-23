import 'package:get/get.dart';

import '../providers/contact_update_provider.dart';
import '../services/api_service.dart';
import '../services/contact_update_service.dart';

// ============================================================
// CONTACT UPDATE BINDING
//
// Registers the write-side dependencies of the Contact Update
// feature:
//
//   - ContactUpdateService  (PATCH phone / PUT address)
//   - ContactUpdateProvider
//
// No read path is registered or triggered: the current address
// stays owned by the existing LoanDashboardProvider
// (loanDetails.value?.borrower?.address), which
// ContactUpdateProvider resolves through Get.find. That
// controller is registered by LoanDashboardBinding (fenix) and
// must be alive when Contact Update opens from the dashboard.
//
// Reuses the single ApiService from AppBinding.
// ============================================================

class ContactUpdateBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // CONTACT UPDATE SERVICE
    //
    // Reuses the single ApiService registered in AppBinding.
    // ============================================================

    Get.lazyPut<ContactUpdateService>(
      () => ContactUpdateService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    // ============================================================
    // CONTACT UPDATE PROVIDER
    //
    // Resolves ContactUpdateService (registered above) and the
    // existing LoanDashboardProvider (registered by
    // LoanDashboardBinding) inside its constructor.
    // ============================================================

    Get.lazyPut<ContactUpdateProvider>(
      () => ContactUpdateProvider(),
      fenix: true,
    );
  }
}
