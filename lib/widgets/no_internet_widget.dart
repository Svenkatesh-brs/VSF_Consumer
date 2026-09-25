import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../utils/app_responsive.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isChecking;

  const NoInternetWidget({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    final double animationWidth = math.min(
      250.0,
      AppResponsive.width(context) * 0.62,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/no_internet.json',
              width: animationWidth,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              'no_internet_title'.tr,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('no_internet_message'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isChecking ? null : onRetry,
              child: isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
