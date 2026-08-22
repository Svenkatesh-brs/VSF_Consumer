import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // AUTH SERVICE
    // ============================================================

    Get.lazyPut<AuthService>(
      () => AuthService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    // ============================================================
    // AUTH PROVIDER
    // ============================================================

    Get.lazyPut<AuthProvider>(
      () => AuthProvider(
        authService: Get.find<AuthService>(),
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}