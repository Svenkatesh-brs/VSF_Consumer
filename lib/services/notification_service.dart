import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/app_constants.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ============================================================
// REQUEST NOTIFICATION PERMISSION
// ============================================================

Future<void> requestNotificationPermission() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

  // ============================================================
  // REGISTER FCM DEVICE
  // ============================================================

  Future<void> registerDevice() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      throw Exception('Unable to get FCM token');
    }

    await _apiService.post(
      AppConstants.registerNotificationDevice,
      data: {
        'fcmToken': fcmToken,
        'deviceType': 'android',
      },
    );
  }
}