import 'package:get/get.dart';

import '../models/in_app_notification_model.dart';
import '../services/in_app_notification_service.dart';

class InAppNotificationProvider extends GetxController {
  final InAppNotificationService _service;

  InAppNotificationProvider({
    required InAppNotificationService service,
  }) : _service = service;

  final notifications = <InAppNotificationModel>[].obs;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;

  final errorMessage = RxnString();

  final currentPage = 0.obs;
  final total = 0.obs;

  static const int _recordsPerPage = 10;

  bool get hasMore =>
      notifications.length < total.value;

  int get unreadCount =>
      notifications.where((item) => !item.isRead).length;

  @override
  void onReady() {
    super.onReady();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    if (isLoading.value) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await _service.getNotifications(
        page: 1,
        recordsPerPage: _recordsPerPage,
      );

      if (!response.success) {
        errorMessage.value = response.message;
        return;
      }

      notifications.assignAll(
        response.notifications,
      );

      currentPage.value = response.page;
      total.value = response.total;
    } catch (e) {
      errorMessage.value =
          'Unable to load notifications.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshNotifications() async {
    if (isRefreshing.value) {
      return;
    }

    try {
      isRefreshing.value = true;

      final response = await _service.getNotifications(
        page: 1,
        recordsPerPage: _recordsPerPage,
      );

      if (!response.success) {
        errorMessage.value = response.message;
        return;
      }

      notifications.assignAll(
        response.notifications,
      );

      currentPage.value = response.page;
      total.value = response.total;
    } catch (e) {
      errorMessage.value =
          'Unable to refresh notifications.';
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) {
      return;
    }

    try {
      isLoadingMore.value = true;

      final nextPage = currentPage.value + 1;

      final response = await _service.getNotifications(
        page: nextPage,
        recordsPerPage: _recordsPerPage,
      );

      if (!response.success) {
        return;
      }

      notifications.addAll(
        response.notifications,
      );

      currentPage.value = response.page;
      total.value = response.total;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markAsRead(
    InAppNotificationModel notification,
  ) async {
    if (notification.isRead) {
      return;
    }

    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );

    if (index == -1) {
      return;
    }

    final previous = notifications[index];

    // Optimistic update.
    notifications[index] = previous.copyWith(
      isRead: true,
    );

    try {
      await _service.updateNotificationReadStatus(
        notificationId: notification.id,
        isRead: true,
      );
    } catch (e) {
      // Rollback if API fails.
      notifications[index] = previous;

      Get.snackbar(
        'Notification',
        'Unable to mark notification as read.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markAsUnread(
    InAppNotificationModel notification,
  ) async {
    if (!notification.isRead) {
      return;
    }

    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );

    if (index == -1) {
      return;
    }

    final previous = notifications[index];

    notifications[index] = previous.copyWith(
      isRead: false,
    );

    try {
      await _service.updateNotificationReadStatus(
        notificationId: notification.id,
        isRead: false,
      );
    } catch (e) {
      notifications[index] = previous;

      Get.snackbar(
        'Notification',
        'Unable to update notification.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}