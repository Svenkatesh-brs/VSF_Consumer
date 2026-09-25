import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  static const double maxContentWidth = 560;

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return (width / 375).clamp(0.85, 1.2).toDouble();
  }

  static double animationSize(
    BuildContext context,
    double size, {
    double fraction = 0.75,
  }) {
    return math.min(size, width(context) * fraction);
  }

  static Widget constrainedContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
