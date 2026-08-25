import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/app_constants.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

  NotificationService({required ApiService apiService})
    : _apiService = apiService;

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _notificationChannel =
      AndroidNotificationChannel(
        'vsf_notifications',
        'VSF Notifications',
        description: 'Notifications from VSF Consumer',
        importance: Importance.high,
      );

  // ============================================================
  // INITIALIZE LOCAL NOTIFICATIONS
  // ============================================================

  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('ic_notification');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_notificationChannel);

    // Listen for FCM messages while the app is in the foreground.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // ============================================================
  // HANDLE FOREGROUND FCM MESSAGE
  // ============================================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    // Ignore data-only messages for now.
    // Background/data-message handling will be implemented
    // in a later Firebase step.
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'VSF Consumer',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannel.id,
          _notificationChannel.name,
          channelDescription: _notificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );
  }

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
    print('FCM TOKEN: $fcmToken');

    await _apiService.post(
      AppConstants.registerNotificationDevice,
      data: {'fcmToken': fcmToken, 'deviceType': 'android'},
    );
  }
}
