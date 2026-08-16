import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AppSubmitButton extends StatelessWidget {
  const AppSubmitButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.sf = 1.0,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double sf;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48 * sf,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [
                    AppColors.buttonStart,
                    AppColors.buttonEnd,
                  ],
                ),
          color: isLoading ? Colors.grey.shade400 : null,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.868,
          ),
          boxShadow: isLoading
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.buttonShadow,
                    blurRadius: 27.79,
                    offset: Offset(0, 13.895),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 15 * sf,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}