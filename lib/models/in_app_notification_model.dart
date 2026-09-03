class InAppNotificationModel {
  final String id;
  final String cid;
  final int type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  const InAppNotificationModel({
    required this.id,
    required this.cid,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory InAppNotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return InAppNotificationModel(
      id: json['id']?.toString() ?? '',
      cid: json['cid']?.toString() ?? '',
      type: _toInt(json['type']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  InAppNotificationModel copyWith({
    bool? isRead,
  }) {
    return InAppNotificationModel(
      id: id,
      cid: cid,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  bool get isEmiReminder => type == 1;

  bool get isEmiPaid => type == 2;

  String get typeLabel {
    switch (type) {
      case 1:
        return 'EMI Reminder';
      case 2:
        return 'EMI Paid';
      default:
        return 'Notification';
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}