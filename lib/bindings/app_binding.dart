import 'package:get/get.dart';

import '../services/api_service.dart';
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
  }
}