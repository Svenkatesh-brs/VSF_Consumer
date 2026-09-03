import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../firebase_options.dart';
import '../routes/app_routes.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('========== BACKGROUND FCM MESSAGE ==========');
  print('Message ID: ${message.messageId}');
  print('Notification title: ${message.notification?.title}');
  print('Notification body: ${message.notification?.body}');
  print('DATA: ${message.data}');
  print('=============================================');
}

class NotificationService {
  final ApiService _apiService;

  NotificationService({
    required ApiService apiService,
  }) : _apiService = apiService;

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
  // INITIALIZE NOTIFICATIONS
  // ============================================================

  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      'ic_notification',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _notificationChannel,
    );

    // ==========================================================
    // FOREGROUND FCM
    // ==========================================================

    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    // ==========================================================
    // BACKGROUND FCM NOTIFICATION TAP
    // ==========================================================

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );

    // ==========================================================
    // TERMINATED APP NOTIFICATION TAP
    // ==========================================================

    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ============================================================
  // HANDLE FCM NOTIFICATION TAP
  // ============================================================

  void _handleNotificationTap(RemoteMessage message) {
    print('========== NOTIFICATION TAP ==========');
    print('Message ID: ${message.messageId}');
    print(
      'Notification title: ${message.notification?.title}',
    );
    print(
      'Notification body: ${message.notification?.body}',
    );
    print('DATA: ${message.data}');
    print('======================================');

    _navigateFromNotificationData(
      message.data,
    );
  }

  // ============================================================
  // HANDLE LOCAL NOTIFICATION TAP
  // ============================================================

  void _handleLocalNotificationTap(
    NotificationResponse response,
  ) {
    final payload = response.payload;

    print('========== LOCAL NOTIFICATION TAP ==========');
    print('Payload: $payload');
    print('============================================');

    if (payload == null || payload.isEmpty) {
      print('Local notification payload is empty.');
      return;
    }

    try {
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;

      print('Decoded local notification data: $data');

      _navigateFromNotificationData(data);
    } catch (e) {
      print(
        'Failed to decode local notification payload: $e',
      );
    }
  }

  // ============================================================
  // NOTIFICATION NAVIGATION
  // ============================================================

  void _navigateFromNotificationData(
    Map<String, dynamic> data,
  ) {
    final type = data['type']?.toString();
    final loanNo = data['loanNo']?.toString();

    print('Notification type: $type');
    print('Notification loanNo: $loanNo');

    switch (type) {
      // --------------------------------------------------------
      // EMI PAYMENT REMINDER
      // --------------------------------------------------------

      case 'EMI_PAYMENT_REMINDER':
        print(
          'Navigating to EMI Schedule screen.',
        );

        Get.toNamed(
          AppRoutes.emiSchedule,
        );
        break;

      // --------------------------------------------------------
      // PAYMENT CONFIRMATION
      // --------------------------------------------------------

      case 'PAYMENT_CONFIRMATION':
        print(
          'Navigating to Transactions screen.',
        );

        Get.toNamed(
          AppRoutes.transactions,
        );
        break;

      // --------------------------------------------------------
      // UNKNOWN TYPE
      // --------------------------------------------------------

      default:
        print(
          'Unknown notification type: $type',
        );
        break;
    }
  }

  // ============================================================
  // HANDLE FOREGROUND FCM MESSAGE
  // ============================================================

  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    print('========== FCM MESSAGE ==========');
    print('Message ID: ${message.messageId}');
    print(
      'Notification title: ${message.notification?.title}',
    );
    print(
      'Notification body: ${message.notification?.body}',
    );
    print('DATA: ${message.data}');
    print('=================================');

    final notification = message.notification;

    // Ignore data-only messages for now.
    if (notification == null) {
      print(
        'Data-only FCM message received. '
        'No local notification will be displayed.',
      );
      return;
    }

    // Convert the FCM data to JSON so that it can be decoded
    // when the local notification is tapped.
    final payload = jsonEncode(
      message.data,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'VSF Consumer',
      body: notification.body ?? '',
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannel.id,
          _notificationChannel.name,
          channelDescription:
              _notificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
    );

    print(
      'Local notification created with payload: $payload',
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
    final fcmToken =
        await FirebaseMessaging.instance.getToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      throw Exception(
        'Unable to get FCM token',
      );
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