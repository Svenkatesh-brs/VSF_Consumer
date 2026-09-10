import 'emi_schedule_model.dart';
import 'loan_details_model.dart';
import 'transactions_model.dart';

// ============================================================
// LOAN API RESPONSE ENVELOPE
//
// Single response of:
//
//   GET /api/v1/consumer/loan/:id
//
// The same "data" object is parsed once and distributed into
// the four domain models:
//
//   - LoanDashboardModel  (overview card)
//   - LoanDetailsModel    (loan details screen)
//   - TransactionsModel   (transactions screen)
//   - EmiScheduleModel    (EMI schedule screen)
// ============================================================

class LoanDashboardResponse {
  final bool success;
  final String message;

  final LoanDashboardModel? dashboard;
  final LoanDetailsModel? details;
  final TransactionsModel? transactions;
  final EmiScheduleModel? emiSchedule;

  const LoanDashboardResponse({
    required this.success,
    required this.message,
    required this.dashboard,
    required this.details,
    required this.transactions,
    required this.emiSchedule,
  });

  factory LoanDashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);

    return LoanDashboardResponse(
      success: json['success'] == true,
      message: _toStr(json['message']),
      dashboard: data == null ? null : LoanDashboardModel.fromJson(data),
      details: data == null ? null : LoanDetailsModel.fromJson(data),
      transactions: data == null ? null : TransactionsModel.fromJson(data),
      emiSchedule: data == null ? null : EmiScheduleModel.fromJson(data),
    );
  }

  bool get hasData => dashboard != null;
}

// ============================================================
// LOAN DASHBOARD MODEL
//
// Data required by the Loan Dashboard Overview Card.
//
// Field sources (actual payload):
//   loanAmount        <- Financial Details
//   outstandingAmount <- installmentDues
//   emiAmount         <- loanSchemes[0].emi
//   outstandingAmount <- installmentDues
//   emiAmount         <- loanSchemes[0].emi
//   vehicleNumber     <- lead.asset.registrationNumber
//   borrowerName      <- lead.borrowers[0].firstName/lastName
//   nextEmiDueDateMs  <- first Pending installments[].dueDate
//   progress          <- totalEMIPaid / totalEMI
// ============================================================

class LoanDashboardModel {
  final String loanId;
  final String loanNo;

  // Vehicle registration number, falling back to the loan
  // number when the asset block is absent.
  final String vehicleNumber;
  final String borrowerName;

  final double loanAmount;
  final double outstandingAmount;
  final double emiAmount;
  final int numberOfInstallments;

  // Epoch milliseconds of the earliest Pending installment.
  // Null when no installment is Pending (the UI renders '-').
  final int? nextEmiDueDateMs;

  final int totalEmiCount;
  final int totalEmiPaidCount;

  // Raw backend status. API status 5 = Inactive, all other
  // statuses = Active (same convention as the Home feature).
  final int statusRaw;

  const LoanDashboardModel({
    required this.loanId,
    required this.loanNo,
    required this.vehicleNumber,
    required this.borrowerName,
    required this.loanAmount,
    required this.outstandingAmount,
    required this.emiAmount,
    required this.numberOfInstallments,
    required this.nextEmiDueDateMs,
    required this.totalEmiCount,
    required this.totalEmiPaidCount,
    required this.statusRaw,
  });

  factory LoanDashboardModel.fromJson(Map<String, dynamic> json) {
    // --------------------------------------------------------
    // NESTED OBJECTS (all optional)
    // --------------------------------------------------------

    final lead = _asMap(json['lead']);
    final asset = lead == null ? null : _asMap(lead['asset']);

    final borrowers = lead == null
        ? <Map<String, dynamic>>[]
        : _mapList(lead['borrowers'], (m) => m);

    final installments = _mapList(json['installments'], (m) => m);

    // --------------------------------------------------------
    // EMI AMOUNT: first installment EMI (used for summary card)
    // --------------------------------------------------------

    final double emiAmount = installments.isNotEmpty
        ? _toDouble(installments.first['emi'])
        : 0;

    // --------------------------------------------------------
    // NUMBER OF INSTALLMENTS
    // --------------------------------------------------------

    final int numberOfInstallments = installments.length;

    // --------------------------------------------------------
    // DISPLAYED LOAN AMOUNT
    //
    // Sum of the EMI amount from every installment returned
    // by the API.
    // --------------------------------------------------------

    double loanAmount = 0;

    for (final installment in installments) {
      loanAmount += _toDouble(installment['emi']);
    }

    // --------------------------------------------------------
    // BORROWER NAME: first borrower with a usable name
    // --------------------------------------------------------

    String borrowerName = '';

    for (final borrower in borrowers) {
      final name =
          '${_toStr(borrower['firstName'])} ${_toStr(borrower['lastName'])}'
              .trim();

      if (name.isNotEmpty) {
        borrowerName = name;
        break;
      }
    }

    print('========== LOAN ID DEBUG ==========');
    print('Loan ID: ${json['id']}');
    print('Loan No: ${json['loanNo']}');
    print('===================================');

    return LoanDashboardModel(
      loanId: _toStr(json['id']),
      loanNo: _toStr(json['loanNo']),
      vehicleNumber: _firstNonEmpty([
        asset?['registrationNumber'],
        json['loanNo'],
      ]),
      borrowerName: borrowerName,
      loanAmount: loanAmount,
      outstandingAmount: _toDouble(json['installmentDues']),
      emiAmount: emiAmount,
      numberOfInstallments: numberOfInstallments,
      nextEmiDueDateMs: _resolveNextEmiDueDateMs(installments),
      totalEmiCount: _toInt(json['totalEMI']),
      totalEmiPaidCount: _toInt(json['totalEMIPaid']),
      statusRaw: _toInt(json['status']),
    );
  }

  String get displayStatus => statusRaw == 5 ? 'Inactive' : 'Active';

  /// Repayment progress as a 0.0 - 1.0 fraction.
  double get repaymentProgress {
    if (totalEmiCount <= 0) {
      return 0;
    }

    return (totalEmiPaidCount / totalEmiCount).clamp(0.0, 1.0).toDouble();
  }

  /// Earliest due date among Pending installments.
  ///
  /// Overdue and Partially-paid installments are excluded so
  /// the dashboard "Next EMI" always points at an upcoming
  /// installment. Returns null when nothing is Pending.
  static int? _resolveNextEmiDueDateMs(
    List<Map<String, dynamic>> installments,
  ) {
    int? earliest;

    for (final installment in installments) {
      final status = _toStr(installment['status']);

      if (status.toLowerCase() != 'pending') {
        continue;
      }

      final dueMs = _toMillis(installment['dueDate']);

      if (dueMs == null) {
        continue;
      }

      if (earliest == null || dueMs < earliest) {
        earliest = dueMs;
      }
    }

    return earliest;
  }
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
/// Accepts numeric values and ISO-8601 strings. Zero dates like
/// "0001-01-01T00:00:00Z" resolve to null instead of a
/// meaningless timestamp.
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = _toStr(value).trim();

    if (text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}
