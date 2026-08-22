import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before the application starts.
  await Hive.initFlutter();

  runApp(
    const VSFConsumerApp(),
  );
}

class VSFConsumerApp extends StatelessWidget {
  const VSFConsumerApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}