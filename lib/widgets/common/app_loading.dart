import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class AppLoading extends StatelessWidget {
  final String message;
  final String? subtitle;
  final double size;

  const AppLoading({
    super.key,
    this.message = 'Loading...',
    this.subtitle,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/app_loading.json',
              width: size,
              height: size,
              fit: BoxFit.contain,
              repeat: true,
            ),

            const SizedBox(height: 4),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTheme.style.copyWith(
                    fontSize: 12,
                    color: AppColors.hint,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}