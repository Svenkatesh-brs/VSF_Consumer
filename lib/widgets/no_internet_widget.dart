import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/no_internet.json',
              width: 250,
              repeat: true,
            ),
            const SizedBox(height: 20),
             Text(
              'no_internet_title'.tr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
             Text(
              'no_internet_message'.tr,
              textAlign: TextAlign.center,
            ),
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