import 'package:get/get.dart';

import '../providers/pay_emi_provider.dart';
import '../services/api_service.dart';
import '../services/pay_emi_service.dart';

class PayEmiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PayEmiService>(
      () => PayEmiService(
        apiService: Get.find<ApiService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<PayEmiProvider>(
      () => PayEmiProvider(
        payEmiService: Get.find<PayEmiService>(),
      ),
      fenix: true,
    );
  }
}