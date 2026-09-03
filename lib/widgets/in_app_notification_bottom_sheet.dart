import 'package:flutter/material.dart';

import '../models/in_app_notification_model.dart';

class InAppNotificationBottomSheet
    extends StatelessWidget {
  final InAppNotificationModel notification;

  const InAppNotificationBottomSheet({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              notification.typeLabel,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              notification.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              notification.body,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Text(
              _formatDate(notification.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}