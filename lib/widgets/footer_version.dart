import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_theme.dart';

class FooterVersion extends StatelessWidget {
  const FooterVersion({
    super.key,
    this.version = '',
    this.environment = '',
  });

  final String version;
  final String environment;

  @override
  Widget build(BuildContext context) {
    final environmentText =
        environment.isNotEmpty ? ' -$environment' : '';

    final versionText =
        version.isNotEmpty ? ': $version' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: Text(
          'Powered By © Nyros Futureworks Pvt Ltd'
          '$versionText'
          '$environmentText',
          style: AppTheme.style.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}