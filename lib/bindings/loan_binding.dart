import 'package:get/get.dart';

import '../providers/loan_provider.dart';

class LoanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanProvider>(
      () => LoanProvider(),
    );
  }
}