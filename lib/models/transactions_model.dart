// ============================================================
// TRANSACTIONS MODEL
//
// Derived from the loan API response:
//
//   data.installments[].payments[]   -> EMI receipts
//   data.vas[].payments[]            -> VAS receipts
//
// One transaction row is produced per payment record that carries
// an actual receipt (EMI or VAS component). LPC and collection
// charges attached to the same payment record stay on that row.
// Records are sorted newest first. Nothing is invented.
// ============================================================

class TransactionsModel {
  final List<LoanTransaction> transactions;

  const TransactionsModel({required this.transactions});

  factory TransactionsModel.fromJson(
    Map<String, dynamic> loanJson,
  ) {
    // ----------------------------------------------------------
    // COLLECT PAYMENT RECORDS
    // ----------------------------------------------------------

    final payments = <Map<String, dynamic>>[];

    for (final installment
        in _mapList(loanJson['installments'], (m) => m)) {
      payments.addAll(
        _mapList(installment['payments'], (m) => m),
      );
    }

    for (final vas in _mapList(loanJson['vas'], (m) => m)) {
      payments.addAll(
        _mapList(vas['payments'], (m) => m),
      );
    }

    // ----------------------------------------------------------
    // PARSE + SORT (newest first, undated rows last)
    // ----------------------------------------------------------

    final transactions = payments
        .map(LoanTransaction.tryParse)
        .whereType<LoanTransaction>()
        .toList();

    transactions.sort((a, b) {
      final aDate = a.dateMs;
      final bDate = b.dateMs;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return TransactionsModel(transactions: transactions);
  }

  bool get isEmpty => transactions.isEmpty;

  int get totalCount => transactions.length;
}

// ============================================================
// SINGLE TRANSACTION RECORD
// ============================================================

class LoanTransaction {
  final String id;

  // Voucher number of the underlying payment voucher.
  final String voucherNo;

  final String description;

  // 'EMI Receipt' or 'VAS Receipt', based on which receipt
  // component the backend attached to the payment record.
  final String type;

  // Main received amount (EMI amount or VAS amount).
  final double amount;

  // Optional components attached to the same payment record.
  final double lpcAmount;
  final double collectionCharge;

  // Epoch milliseconds. Null when no usable date exists.
  final int? dateMs;

  const LoanTransaction({
    required this.id,
    required this.voucherNo,
    required this.description,
    required this.type,
    required this.amount,
    required this.lpcAmount,
    required this.collectionCharge,
    required this.dateMs,
  });

  /// Returns null when the payment record carries no EMI/VAS
  /// receipt component (nothing was actually received).
  static LoanTransaction? tryParse(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // A payment row can carry up to three receipt components:
    // emi / vasDue as the main one plus lpcDue and
    // collectionCharges as extras. All may be null/missing.
    // --------------------------------------------------------

    final emiComponent = _asMap(json['emi']);
    final vasComponent = _asMap(json['vasDue']);

    final mainComponent = emiComponent ?? vasComponent;

    if (mainComponent == null) {
      return null;
    }

    final lpcComponent = _asMap(json['lpcDue']);
    final chargesComponent =
        _asMap(json['collectionCharges']);
    final voucher = _asMap(json['voucher']);

    return LoanTransaction(
      id: _toStr(json['id']),
      voucherNo: _toStr(voucher?['voucherNo']),
      description: _firstNonEmpty([
        voucher?['description'],
        mainComponent['description'],
      ]),
      type: emiComponent != null
          ? 'EMI Receipt'
          : 'VAS Receipt',
      amount: _toDouble(mainComponent['amount']),
      lpcAmount: lpcComponent == null
          ? 0
          : _toDouble(lpcComponent['amount']),
      collectionCharge: chargesComponent == null
          ? 0
          : _toDouble(chargesComponent['amount']),
      dateMs: _toMillis(voucher?['createdAt']) ??
          _toMillis(json['createdAt']) ??
          _toMillis(mainComponent['createdAt']),
    );
  }

  bool get hasExtras =>
      lpcAmount > 0 || collectionCharge > 0;

  double get totalAmount =>
      amount + lpcAmount + collectionCharge;
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
