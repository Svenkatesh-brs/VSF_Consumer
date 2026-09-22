import 'package:get/get.dart';

import '../providers/network_provider.dart';
import '../services/network_service.dart';
import '../providers/language_selection_provider.dart';
import '../services/language_selection_service.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================================
    // STORAGE SERVICE
    // ============================================================

    Get.lazyPut<StorageService>(() => StorageService(), fenix: true);

    // ============================================================
    // LANGUAGE SELECTION SERVICE
    // ============================================================

    Get.lazyPut<LanguageSelectionService>(
      () =>
          LanguageSelectionService(storageService: Get.find<StorageService>()),
      fenix: true,
    );

    // ============================================================
    // LANGUAGE SELECTION PROVIDER
    // ============================================================

    Get.put<LanguageSelectionProvider>(
      LanguageSelectionProvider(
        languageService: Get.find<LanguageSelectionService>(),
      ),
      permanent: true,
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

    // ============================================================
    // NOTIFICATION SERVICE
    // ============================================================

    Get.lazyPut<NotificationService>(
      () => NotificationService(apiService: Get.find<ApiService>()),
      fenix: true,
    );

    // ============================================================
    // AUTH SERVICE
    // ============================================================

    Get.put<AuthService>(
      AuthService(apiService: Get.find<ApiService>()),
      permanent: true,
    );

    // ============================================================
    // AUTH PROVIDER
    // ============================================================

    Get.put<AuthProvider>(
      AuthProvider(
        authService: Get.find<AuthService>(),
        storageService: Get.find<StorageService>(),
        notificationService: Get.find<NotificationService>(),
      ),
      permanent: true,
    );

    // ============================================================
    // NETWORK SERVICE
    // ============================================================

    Get.lazyPut<NetworkService>(() => NetworkService(), fenix: true);

    // ============================================================
    // NETWORK PROVIDER
    // ============================================================

    Get.put<NetworkProvider>(
      NetworkProvider(networkService: Get.find<NetworkService>())..initialize(),
      permanent: true,
    );
  }
}
