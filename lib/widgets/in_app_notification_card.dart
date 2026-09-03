import 'package:flutter/material.dart';

import '../models/in_app_notification_model.dart';
import '../utils/app_colors.dart';

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

    final showUnreadTint = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: showUnreadTint
              ? AppColors.lightBlue.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: showUnreadTint
                ? AppColors.lightBlue.withValues(alpha: 0.15)
                : theme.dividerColor.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                            color: showUnreadTint
                                ? AppColors.lightBlue
                                : Colors.black87,
                            fontWeight: showUnreadTint
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showUnreadTint)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(
                            left: 8,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatRelativeTime(
                            notification.createdAt,
                          ),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color: Colors.black45,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    IconData icon;
    Color color;

    if (notification.isEmiReminder) {
      icon = Icons.notifications_active_outlined;
      color = AppColors.secondary;
    } else if (notification.isEmiPaid) {
      icon = Icons.check_circle_outline;
      color = AppColors.primary;
    } else {
      icon = Icons.notifications_none_rounded;
      color = AppColors.lightBlue;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: color,
      ),
    );
  }
}