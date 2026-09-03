import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/in_app_notification_model.dart';
import '../providers/in_app_notification_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/in_app_notification_bottom_sheet.dart';
import '../widgets/in_app_notification_card.dart';

class InAppNotificationScreen extends GetView<
    InAppNotificationProvider> {
  const InAppNotificationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: AppColors.lightBlue,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                14,
              ),
              child: _SegmentedTabBar(controller: controller),
            ),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value &&
              controller.notifications.isEmpty) {
            return const _LoadingState();
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

          return TabBarView(
            children: [
              _NotificationList(
                notifications:
                    controller.unreadNotifications,
                emptyTitle: 'No new notifications',
                emptySubtitle:
                    'You are all caught up',
                emptyIcon:
                    Icons.mark_email_read_outlined,
                onTap: _showNotification,
                controller: controller,
                scrollController:
                    _UnreadScrollController.instance,
              ),
              _NotificationList(
                notifications:
                    controller.seenNotifications,
                emptyTitle:
                    'No notifications seen yet',
                emptySubtitle:
                    'Notifications you open will '
                    'appear here',
                emptyIcon:
                    Icons.notifications_off_outlined,
                onTap: _showNotification,
                controller: controller,
                scrollController:
                    _SeenScrollController.instance,
              ),
            ],
          );
        }),
      ),
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

// ------------------------------------------------------------------
// SHARED SCROLL CONTROLLERS SO EACH TAB KEEPS ITS OWN POSITION
// ------------------------------------------------------------------

class _UnreadScrollController {
  static final ScrollController instance =
      ScrollController();
}

class _SeenScrollController {
  static final ScrollController instance =
      ScrollController();
}

// ------------------------------------------------------------------
// SEGMENTED TAB BAR
// ------------------------------------------------------------------

class _SegmentedTabBar extends StatelessWidget {
  final InAppNotificationProvider controller;

  const _SegmentedTabBar({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.lightBlue,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Obx(
            () => _TabItem(
              label: 'Unread',
              showCount: controller.unreadCount > 0,
              count: controller.unreadCount,
            ),
          ),
          const _TabItem(
            label: 'Seen',
            showCount: false,
            count: 0,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool showCount;
  final int count;

  const _TabItem({
    required this.label,
    required this.showCount,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (showCount) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------
// NOTIFICATION LIST (shared by both tabs)
// ------------------------------------------------------------------

class _NotificationList extends StatelessWidget {
  final List<InAppNotificationModel> notifications;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final InAppNotificationProvider controller;
  final ScrollController scrollController;
  final void Function(
    BuildContext,
    InAppNotificationModel,
  )
  onTap;

  const _NotificationList({
    required this.notifications,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.controller,
    required this.scrollController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshNotifications,
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
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              notifications.length +
                  (controller.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= notifications.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            final notification = notifications[index];

            return InAppNotificationCard(
              notification: notification,
              onTap: () => onTap(context, notification),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// STATES
// ------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 36,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.lightBlue,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
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
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 30,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lightBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
