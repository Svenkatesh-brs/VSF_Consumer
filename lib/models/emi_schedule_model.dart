import 'package:flutter/foundation.dart';

// ============================================================
// EMI SCHEDULE MODEL
//
// Derived directly from the loan API response:
//
//   GET /api/v1/consumer/loan/:id  ->  data.installments[]
//
// Past EMIs arrive with status Paid / Partial / Overdue and
// future EMIs arrive with status Pending. No EMI records are
// created on the client side.
// ============================================================

class EmiScheduleModel {
  final List<EmiItem> emis;

  const EmiScheduleModel({required this.emis});

  factory EmiScheduleModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmiScheduleModel(
      emis: _mapList(
        json['installments'],
        EmiItem.fromJson,
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY HELPERS
  // ------------------------------------------------------------

  bool get isEmpty => emis.isEmpty;

  int get totalCount => emis.length;

  int get paidCount =>
      emis.where((emi) => emi.isPaid).length;

  int get overdueCount =>
      emis.where((emi) => emi.isOverdue).length;

  int get upcomingCount =>
      emis.where((emi) => emi.isUpcoming).length;
}

// ============================================================
// SINGLE EMI RECORD
// ============================================================

class EmiItem {
  final String id;

  // Epoch milliseconds. Null when the API provides no usable date.
  final int? dueDateMs;

  final double emiAmount;
  final double principalComponent;
  final double interestComponent;
  final double insuranceComponent;
  final double principalOutstanding;
  final double lpcDue;
  final double discount;

  // Payment summary for this EMI. lastPaymentDateMs is null when
  // the EMI has never received a payment.
  final double totalPaid;
  final double totalLpcPaid;
  final double remainingAmount;
  final int? lastPaymentDateMs;

  // Raw backend status: Paid / Partial / Overdue / Pending.
  final String status;
  final int daysOverdue;

  const EmiItem({
    required this.id,
    required this.dueDateMs,
    required this.emiAmount,
    required this.principalComponent,
    required this.interestComponent,
    required this.insuranceComponent,
    required this.principalOutstanding,
    required this.lpcDue,
    required this.discount,
    required this.totalPaid,
    required this.totalLpcPaid,
    required this.remainingAmount,
    required this.lastPaymentDateMs,
    required this.status,
    required this.daysOverdue,
  });

  factory EmiItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final result = EmiItem(
      id: _toStr(json['id']),
      dueDateMs: _toMillis(json['dueDate']),
      emiAmount: _toDouble(json['emi']),
      principalComponent:
          _toDouble(json['principal']),
      interestComponent:
          _toDouble(json['interest']),
      insuranceComponent:
          _toDouble(json['insurance']),
      principalOutstanding:
          _toDouble(json['principalOutstanding']),
      lpcDue: _toDouble(json['lpcDue']),
      discount: _toDouble(json['discount']),
      totalPaid: _toDouble(json['totalPaid']),
      totalLpcPaid:
          _toDouble(json['totalLPCPaid']),
      remainingAmount:
          _toDouble(json['remainingAmount']),
      lastPaymentDateMs:
          _toMillis(json['lastPaymentDate']),
      status: _toStr(json['status']),
      daysOverdue: _calculateDaysOverdue(json),
    );

    debugPrint(
      '[EMI DEBUG] id=${json['id']} | '
      'status=${json['status']} | '
      'daysOverdue=${json['daysOverdue']} | '
      'dueDate=${json['dueDate']} | '
      'payments=${json['payments']} | '
      'calculated=${result.daysOverdue}',
    );

    return result;
  }

  // ------------------------------------------------------------
  // STATUS HELPERS
  // ------------------------------------------------------------

  bool get isPaid =>
      status.toLowerCase() == 'paid';

  bool get isPartial =>
      status.toLowerCase() == 'partial';

  bool get isOverdue =>
      status.toLowerCase() == 'overdue';

  // An unknown/missing status is treated as a future EMI so it
  // never renders as an already-paid record.
  bool get isPending =>
      status.isEmpty ||
      status.toLowerCase() == 'pending';

  /// Already-due EMI (paid, partially paid or overdue).
  bool get isPast => !isPending;

  /// Future EMI that has not fallen due yet.
  bool get isUpcoming => isPending;
}

// ============================================================
// SAFE PARSING HELPERS
// ============================================================

String _toStr(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

int _calculateDaysOverdue(
  Map<String, dynamic> json,
) {
  var total = _toInt(json['daysOverdue']);

  final payments = json['payments'];

  if (payments is List) {
    for (final payment in payments) {
      if (payment is Map &&
          payment['isLatestPayment'] == true) {
        total += _toInt(payment['lpcDueDays']);
        break;
      }
    }
  }

  // When the installment is Overdue but the combined value is
  // still 0 (e.g. daysOverdue was 0 and no latest payment
  // carries lpcDueDays), compute overdue days from dueDate.
  if (total == 0 &&
      _toStr(json['status']).toLowerCase() == 'overdue') {
    final dueMs = _toMillis(json['dueDate']);

    if (dueMs != null) {
      final now = DateTime.now();
      final due = DateTime.fromMillisecondsSinceEpoch(dueMs);
      final diff = now.difference(due).inDays;

      if (diff > 0) {
        total = diff;
      }
    }
  }

  return total;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  return 0.0;
}

/// Epoch-milliseconds parser.
///
/// Accepts numeric values (int/double/numeric string) and ISO-8601
/// strings such as "2026-03-20T06:24:24.528Z". Zero dates like
/// "0001-01-01T00:00:00Z" and zero/0 epoch values resolve to null
/// instead of a meaningless timestamp.
int? _toMillis(dynamic value) {
  if (value is num) {
    final ms = value.toInt();

    return ms > 0 ? ms : null;
  }

  if (value is String) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final numeric = int.tryParse(trimmed);

    if (numeric != null) {
      return numeric > 0 ? numeric : null;
    }

    final parsed = DateTime.tryParse(trimmed);

    if (parsed == null) {
      return null;
    }

    final ms = parsed.millisecondsSinceEpoch;

    return ms > 0 ? ms : null;
  }

  return null;
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}
