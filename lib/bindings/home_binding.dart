import 'package:get/get.dart';

import '../providers/home_provider.dart';
import '../services/api_service.dart';
import '../services/home_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // HOME SERVICE
    // ============================================================

    Get.lazyPut<HomeService>(
      () => HomeService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    // ============================================================
    // HOME PROVIDER
    // ============================================================

    Get.lazyPut<HomeProvider>(
      () => HomeProvider(
        homeService: Get.find<HomeService>(),
      ),
      fenix: true,
    );
  }
}