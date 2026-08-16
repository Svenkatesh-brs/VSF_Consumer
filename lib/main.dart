import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const VSFConsumerApp());
}

class VSFConsumerApp extends StatelessWidget {
  const VSFConsumerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
  title: 'VSF Consumer',
  debugShowCheckedModeBanner: false,
  initialBinding: AppBinding(),
  initialRoute: AppRoutes.login,
  getPages: AppPages.pages,
);
  }
}