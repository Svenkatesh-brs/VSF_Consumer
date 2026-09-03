import 'package:get/get.dart';

import '../providers/in_app_notification_provider.dart';
import '../services/api_service.dart';
import '../services/in_app_notification_service.dart';

class InAppNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InAppNotificationService>(
      () => InAppNotificationService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<InAppNotificationProvider>(
      () => InAppNotificationProvider(
        service: Get.find<InAppNotificationService>(),
      ),
      fenix: true,
    );
  }
}