import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/in_app_notification_model.dart';
import '../providers/in_app_notification_provider.dart';
import '../widgets/in_app_notification_bottom_sheet.dart';
import '../widgets/in_app_notification_card.dart';

class InAppNotificationScreen extends GetView<
    InAppNotificationProvider> {
  const InAppNotificationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.notifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value != null &&
            controller.notifications.isEmpty) {
          return _ErrorState(
            message:
                controller.errorMessage.value!,
            onRetry:
                controller.loadNotifications,
          );
        }

        if (controller.notifications.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh:
              controller.refreshNotifications,
          child: NotificationListener<
              ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent -
                      200) {
                controller.loadMore();
              }

              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount:
                  controller.notifications.length +
                      (controller.isLoadingMore.value
                          ? 1
                          : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >=
                    controller.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final notification =
                    controller.notifications[index];

                return InAppNotificationCard(
                  notification: notification,
                  onTap: () =>
                      _showNotification(
                    context,
                    notification,
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showNotification(
    BuildContext context,
    InAppNotificationModel notification,
  ) async {
    // Mark as read immediately.
    await controller.markAsRead(
      notification,
    );

    if (!context.mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Material(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: InAppNotificationBottomSheet(
            notification: notification.copyWith(
              isRead: true,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No notifications yet',
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}