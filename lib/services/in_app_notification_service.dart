import '../models/in_app_notification_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class InAppNotificationResponse {
  final bool success;
  final String message;
  final List<InAppNotificationModel> notifications;
  final int page;
  final int recordsPerPage;
  final int total;

  const InAppNotificationResponse({
    required this.success,
    required this.message,
    required this.notifications,
    required this.page,
    required this.recordsPerPage,
    required this.total,
  });
}

class InAppNotificationService {
  final ApiService _apiService;

  InAppNotificationService({required ApiService apiService})
    : _apiService = apiService;

  Future<InAppNotificationResponse> getNotifications({
    required int page,
    int recordsPerPage = 10,
    String searchString = '',
  }) async {
    print('========== IN APP NOTIFICATION API ==========');
    print('Endpoint: ${AppConstants.notifications}');
    print('Page: $page');
    print('Records Per Page: $recordsPerPage');
    print('Search String: $searchString');

    final response = await _apiService.get(
      AppConstants.notifications,
      data: {
        'page': page,
        'recordsPerPage': recordsPerPage,
        'searchString': searchString,
      },
    );

    print('Status Code: ${response.statusCode}');
    print('Response Data: ${response.data}');
    print('=============================================');

    if (response.data is! Map) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid notification response.',
      );
    }

    final json = Map<String, dynamic>.from(response.data as Map);

    final rawData = json['data'];

    final notifications = rawData is List
        ? rawData
              .whereType<Map>()
              .map(
                (item) => InAppNotificationModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <InAppNotificationModel>[];

    return InAppNotificationResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      notifications: notifications,
      page: _toInt(json['page'], page),
      recordsPerPage: _toInt(json['recordsPerPage'], recordsPerPage),
      total: _toInt(json['total'], 0),
    );
  }

  Future<void> updateNotificationReadStatus({
    required String notificationId,
    required bool isRead,
  }) async {
    final response = await _apiService.patch(
      '${AppConstants.notifications}/$notificationId',
      data: {'isRead': isRead},
    );

    if (response.data is! Map) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid notification update response.',
      );
    }

    final json = Map<String, dynamic>.from(response.data as Map);

    if (json['success'] != true) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            json['message']?.toString() ?? 'Unable to update notification.',
      );
    }
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
