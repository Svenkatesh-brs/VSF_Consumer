import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class HomeSummaryCard extends StatelessWidget {
  const HomeSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final accentColor = iconColor ?? AppColors.primary;

    return Container(
      height: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.78),
            Colors.white.withValues(alpha: 0.42),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // ICON
          // --------------------------------------------------------
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: accentColor,
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // VALUE
          // --------------------------------------------------------
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
              height: 1,
            ),
          ),

          const SizedBox(height: 6),

          // --------------------------------------------------------
          // TITLE
          // --------------------------------------------------------
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}