import 'package:get/get.dart';

import '../providers/auth_provider.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    GetInstance().lazyPut<AuthProvider>(
      () => AuthProvider(),
      fenix: true,
      permanent: true,
    );
  }
}