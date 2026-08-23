// ============================================================
// COMPLAINT MODEL
// ============================================================

class ComplaintModel {
  const ComplaintModel({
    required this.id,
    required this.description,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String description;
  final String createdBy;
  final int status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------

  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;

  String get statusLabel {
    switch (status) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  // ------------------------------------------------------------
  // FROM JSON
  // ------------------------------------------------------------

  factory ComplaintModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ComplaintModel(
      id: _toString(json['id']),
      description: _toString(json['description']),
      createdBy: _toString(json['createdBy']),
      status: _toInt(json['status']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  // ------------------------------------------------------------
  // TO JSON
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// ============================================================
// CREATE COMPLAINT REQUEST
// ============================================================

class ComplaintCreateRequest {
  const ComplaintCreateRequest({
    required this.description,
    required this.urgent,
    required this.issueType,
  });

  final String description;
  final bool urgent;
  final int issueType;

  // ------------------------------------------------------------
  // ISSUE TYPES
  // ------------------------------------------------------------

  static const int billingOrPayment = 1;
  static const int documents = 2;
  static const int serviceQuality = 3;
  static const int vehicleRelated = 4;
  static const int other = 5;

  String get issueTypeLabel {
    switch (issueType) {
      case billingOrPayment:
        return 'Billing or Payment';
      case documents:
        return 'Documents';
      case serviceQuality:
        return 'Service Quality';
      case vehicleRelated:
        return 'Vehicle Related';
      case other:
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  // ------------------------------------------------------------
  // TO JSON
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'urgent': urgent,
      'issueType': issueType,
    };
  }
}

// ============================================================
// CREATE COMPLAINT RESPONSE
// ============================================================

class ComplaintCreateResponse {
  const ComplaintCreateResponse({
    required this.data,
    required this.message,
    required this.success,
  });

  final ComplaintModel? data;
  final String message;
  final bool success;

  // ------------------------------------------------------------
  // FROM JSON
  // ------------------------------------------------------------

  factory ComplaintCreateResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];

    return ComplaintCreateResponse(
      data: rawData is Map
          ? ComplaintModel.fromJson(
              Map<String, dynamic>.from(rawData),
            )
          : null,
      message: _toString(json['message']),
      success: json['success'] == true,
    );
  }
}

// ============================================================
// COMPLAINT LIST REQUEST
// ============================================================

class ComplaintListRequest {
  const ComplaintListRequest({
    required this.status,
    required this.page,
    required this.recordsPerPage,
  });

  final int status;
  final int page;
  final int recordsPerPage;

  // ------------------------------------------------------------
  // TO JSON
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'page': page,
      'recordsPerPage': recordsPerPage,
    };
  }
}

// ============================================================
// COMPLAINT LIST RESPONSE
// ============================================================

class ComplaintListResponse {
  const ComplaintListResponse({
    required this.data,
    required this.message,
    required this.page,
    required this.recordsPerPage,
    required this.success,
    required this.total,
  });

  final List<ComplaintModel> data;
  final String message;
  final int page;
  final int recordsPerPage;
  final bool success;
  final int total;

  // ------------------------------------------------------------
  // FROM JSON
  // ------------------------------------------------------------

  factory ComplaintListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];

    final complaints = rawData is List
        ? rawData
            .whereType<Map>()
            .map(
              (item) => ComplaintModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <ComplaintModel>[];

    return ComplaintListResponse(
      data: complaints,
      message: _toString(json['message']),
      page: _toInt(json['page']),
      recordsPerPage: _toInt(json['recordsPerPage']),
      success: json['success'] == true,
      total: _toInt(json['total']),
    );
  }
}

// ============================================================
// SAFE JSON HELPERS
// ============================================================

String _toString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(trimmed);
  }

  return null;
}