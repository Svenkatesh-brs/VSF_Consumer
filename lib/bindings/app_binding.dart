import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // STORAGE SERVICE
    // ============================================================

    Get.lazyPut<StorageService>(
      () => StorageService(),
      fenix: true,
    );

    // ============================================================
    // API SERVICE
    // ============================================================

    Get.lazyPut<ApiService>(
      () => ApiService(
        baseUrl: AppConstants.baseUrl,
        storageService: Get.find<StorageService>(),
      ),
      fenix: true,
    );

    // ============================================================
    // AUTH SERVICE
    //
    // Application-wide. Eagerly initialized inside initialBinding,
    // before any route exists, so GetX never links it to a route
    // and SmartManagement never disposes it.
    // ============================================================

    Get.put<AuthService>(
      AuthService(
        apiService: Get.find<ApiService>(),
      ),
      permanent: true,
    );

    // ============================================================
    // AUTH PROVIDER
    //
    // Application-wide. Used by Login, OTP, Home and Logout, so it
    // must NOT be registered per route (a route-scoped registration
    // gets its onClose() called when that route is removed, which
    // disposed mobileController/otpController after logout).
    //
    // Eager + permanent = one stable instance for the whole app;
    // onClose() only runs at app shutdown.
    // ============================================================

    Get.put<AuthProvider>(
      AuthProvider(
        authService: Get.find<AuthService>(),
        storageService: Get.find<StorageService>(),
      ),
      permanent: true,
    );
  }
}