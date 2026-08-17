import 'package:get/get.dart';

import '../providers/splash_provider.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashProvider>(
      () => SplashProvider(),
    );
  }
}