import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notification_service.dart';
import 'bindings/app_binding.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'translations/language_selection_translations.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Read the saved language from the existing Hive box.
  final box = await Hive.openBox<dynamic>('vsf_storage');
  final savedLanguageCode = box.get('selected_language_code') as String?;

  final Locale initialLocale;

  switch (savedLanguageCode) {
    case 'te':
      initialLocale = const Locale('te', 'IN');
      break;
    case 'hi':
      initialLocale = const Locale('hi', 'IN');
      break;
    case 'en':
    default:
      initialLocale = const Locale('en', 'US');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(VSFConsumerApp(initialLocale: initialLocale));
}

class VSFConsumerApp extends StatelessWidget {
  final Locale initialLocale;

  const VSFConsumerApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      // Localization
      translations: LanguageSelectionTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),

      // Existing app setup
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
