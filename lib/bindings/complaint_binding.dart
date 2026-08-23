import 'package:get/get.dart';

import '../providers/complaint_provider.dart';
import '../services/api_service.dart';
import '../services/complaint_service.dart';

class ComplaintBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // COMPLAINT SERVICE
    // ============================================================

    Get.lazyPut<ComplaintService>(
      () => ComplaintService(
        apiService: Get.find<ApiService>(),
      ),
    );

    // ============================================================
    // COMPLAINT PROVIDER
    // ============================================================

    Get.lazyPut<ComplaintProvider>(
      () => ComplaintProvider(
        complaintService: Get.find<ComplaintService>(),
      ),
    );
  }
}