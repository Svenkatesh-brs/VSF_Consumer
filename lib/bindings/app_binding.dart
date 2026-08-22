import 'package:get/get.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // API SERVICE
    // ============================================================

    Get.lazyPut<ApiService>(
      () => ApiService(
        baseUrl: AppConstants.baseUrl,
      ),
      fenix: true,
    );

    // ============================================================
    // STORAGE SERVICE
    // ============================================================

    Get.lazyPut<StorageService>(
      () => StorageService(),
      fenix: true,
    );
  }
}