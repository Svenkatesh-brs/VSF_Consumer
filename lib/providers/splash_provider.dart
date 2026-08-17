import 'package:get/get.dart';

import '../routes/app_routes.dart';

class SplashProvider extends GetxController {
  @override
  void onReady() {
    super.onReady();

    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    if (Get.currentRoute == AppRoutes.splash) {
      Get.offNamed(AppRoutes.login);
    }
  }
}