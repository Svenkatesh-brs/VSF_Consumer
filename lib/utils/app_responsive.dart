import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return (width / 375).clamp(0.85, 1.2);
  }
}