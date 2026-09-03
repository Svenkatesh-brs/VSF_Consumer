import 'package:flutter/material.dart';

import '../models/in_app_notification_model.dart';

class InAppNotificationCard extends StatelessWidget {
  final InAppNotificationModel notification;
  final VoidCallback onTap;

  const InAppNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surface
              : theme.colorScheme.primary.withValues(
                  alpha: 0.06,
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? theme.dividerColor.withValues(alpha: 0.12)
                : theme.colorScheme.primary.withValues(
                    alpha: 0.18,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(
              notification: notification,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRelativeTime(
                      notification.createdAt,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final difference =
        DateTime.now().difference(date.toLocal());

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotificationIcon extends StatelessWidget {
  final InAppNotificationModel notification;

  const _NotificationIcon({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;

    if (notification.isEmiReminder) {
      icon = Icons.notifications_active_outlined;
    } else if (notification.isEmiPaid) {
      icon = Icons.check_circle_outline;
    } else {
      icon = Icons.notifications_none;
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(
          alpha: 0.10,
        ),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
    );
  }
}