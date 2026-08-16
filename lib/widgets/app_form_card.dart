import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.child,
    this.sf = 1.0,
  });

  final Widget child;
  final double sf;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.40),
            Colors.white.withValues(alpha: 0.18),
          ],
          stops: const [
            0.228,
            0.993,
          ],
        ),
        borderRadius: BorderRadius.circular(22 * sf),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * sf,
        vertical: 18 * sf,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.inputFill,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12 * sf,
              vertical: 14 * sf,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * sf),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 0.658,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * sf),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: 0.658,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * sf),
              borderSide: const BorderSide(
                color: AppColors.inputFocused,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * sf),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 0.658,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8 * sf),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.0,
              ),
            ),
            hintStyle: TextStyle(
              fontSize: 12 * sf,
              color: AppColors.hint,
              fontWeight: FontWeight.w400,
            ),
            errorStyle: TextStyle(
              fontSize: 9.5 * sf,
              color: const Color(0xE6D30505),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}