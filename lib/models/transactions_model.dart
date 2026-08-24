// ============================================================
// TRANSACTIONS MODEL
//
// Derived from the loan API response:
//
//   data.installments[].payments[]   -> EMI receipts
//   data.vas[].payments[]            -> VAS receipts
//
// ONE TRANSACTION CARD PER VOUCHER:
//
// Payment records are grouped by payment.voucher.id so that a
// single real-world receipt (one voucher) covering several
// installments, or carrying EMI + LPC + collection charges (+
// VAS + seize charges), renders as exactly one card.
//
// For every voucher group the merged amounts are the sums of
// the individual receipt components actually attached to the
// grouped payment records:
//
//   amountCollected = emi.amount
//                   + lpcDue.amount
//                   + collectionCharges.amount
//                   + vasDue.amount
//                   + seizeCharges.amount
//
// NULL SAFETY:
//
// The backend legitimately returns null (or omits) optional
// components: emi, lpcDue, collectionCharges, vasDue,
// seizeCharges. Every component amount is read through a
// null-safe chain equivalent to `component?.amount ?? 0.0`,
// so a completely null component contributes exactly 0.0 to
// its group total and never hides or drops the payment.
//
// Installment-level cumulative fields (totalPaid,
// totalLPCPaid, remainingAmount, status) intentionally stay on
// EmiItem and are never used as a receipt/card amount.
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
    // PARSE RAW RECORDS
    //
    // A record with none of the five receipt components carries
    // no financial event and is skipped. Records that carry only
    // LPC / collection charges / seize charges are kept: they
    // must still participate in their voucher's merge.
    // ----------------------------------------------------------

    final parsed = payments
        .map(_RawPayment.parse)
        .whereType<_RawPayment>()
        .toList();

    // ----------------------------------------------------------
    // GROUP BY VOUCHER
    //
    // Group key = payment.voucher.id. Records without a usable
    // voucher id fall back to their own payment-record id so no
    // valid record is ever dropped.
    // ----------------------------------------------------------

    final groups = <String, List<_RawPayment>>{};

    for (final payment in parsed) {
      groups
          .putIfAbsent(payment.groupKey, () => [])
          .add(payment);
    }

    // ----------------------------------------------------------
    // BUILD MERGED CARDS
    // ----------------------------------------------------------

    final transactions = groups.values
        .map(_mergeGroup)
        .whereType<LoanTransaction>()
        .toList();

    // ----------------------------------------------------------
    // SORT (newest first, undated rows last)
    // ----------------------------------------------------------

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

  /// Merges every payment record of one voucher into a single
  /// card. Returns null when the group holds no collected money
  /// at all (defensive guard against empty ghost receipts).
  static LoanTransaction? _mergeGroup(
    List<_RawPayment> records,
  ) {
    double emiAmount = 0;
    double vasAmount = 0;
    double lpcAmount = 0;
    double collectionCharge = 0;
    double seizeCharge = 0;

    int? latestDateMs;
    final paymentIds = <String>[];
    String? voucherId;
    String? voucherNo;
    String? instrumentNo;

    for (final record in records) {
      emiAmount += record.emiAmount;
      vasAmount += record.vasAmount;
      lpcAmount += record.lpcAmount;
      collectionCharge += record.collectionCharge;
      seizeCharge += record.seizeCharge;

      if (record.dateMs != null &&
          (latestDateMs == null ||
              record.dateMs! > latestDateMs)) {
        latestDateMs = record.dateMs;
      }

      paymentIds.add(record.id);
      voucherId ??= record.voucherId;
      voucherNo ??= record.voucherNo;
      instrumentNo ??= record.instrumentNo;
    }

    final amountCollected = emiAmount +
        lpcAmount +
        collectionCharge +
        vasAmount +
        seizeCharge;

    if (amountCollected <= 0) {
      return null;
    }

    return LoanTransaction(
      voucherId: voucherId ?? '',
      voucherNo: voucherNo ?? '',
      description: _resolveDescription(records),
      type: _resolveType(
        emiAmount: emiAmount,
        vasAmount: vasAmount,
      ),
      emiAmount: emiAmount,
      vasAmount: vasAmount,
      lpcAmount: lpcAmount,
      collectionCharge: collectionCharge,
      seizeCharge: seizeCharge,
      amountCollected: amountCollected,
      instrumentNo: instrumentNo ?? '',
      dateMs: latestDateMs,
      paymentIds: paymentIds,
    );
  }

  // ------------------------------------------------------------
  // GROUP HELPERS
  // ------------------------------------------------------------

  /// Voucher description first (stable across the group), then
  /// the first non-empty component description of any record.
  static String _resolveDescription(
    List<_RawPayment> records,
  ) {
    for (final record in records) {
      final text = _toStr(record.voucherDescription).trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    for (final record in records) {
      for (final text in record.componentDescriptions) {
        final trimmed = text.trim();

        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return '';
  }

  /// Receipt type derived from the merged components.
  static String _resolveType({
    required double emiAmount,
    required double vasAmount,
  }) {
    final hasEmi = emiAmount > 0;
    final hasVas = vasAmount > 0;

    if (hasEmi && hasVas) {
      return 'Mixed Receipt';
    }

    if (hasEmi) {
      return 'EMI Receipt';
    }

    if (hasVas) {
      return 'VAS Receipt';
    }

    // Only LPC / collection charges / seize charges were
    // collected on this voucher.
    return 'Charges Receipt';
  }

  bool get isEmpty => transactions.isEmpty;

  int get totalCount =>
      transactions.length; // merged vouchers/receipts
}

// ============================================================
// SINGLE TRANSACTION RECORD (ONE VOUCHER / ONE RECEIPT)
// ============================================================

class LoanTransaction {
  // Voucher identity. voucher.id doubles as the grouping key.
  final String voucherId;
  final String voucherNo;

  final String description;

  // 'EMI Receipt', 'VAS Receipt', 'Mixed Receipt' or
  // 'Charges Receipt', derived from the merged components.
  final String type;

  // Individual collected components summed across all payment
  // records sharing this voucher.
  final double emiAmount;
  final double vasAmount;
  final double lpcAmount;
  final double collectionCharge;
  final double seizeCharge;

  // Actual amount collected on this receipt:
  // emi + vas + lpc + collection charges + seize charges.
  final double amountCollected;

  // First non-empty instrument number found on the grouped
  // payment records' components. Empty when none was captured.
  final String instrumentNo;

  // Latest valid payment date within the merged group.
  // Epoch milliseconds. Null when no usable date exists.
  final int? dateMs;

  // Source payment-record ids behind this merged card.
  final List<String> paymentIds;

  const LoanTransaction({
    required this.voucherId,
    required this.voucherNo,
    required this.description,
    required this.type,
    required this.emiAmount,
    required this.vasAmount,
    required this.lpcAmount,
    required this.collectionCharge,
    required this.seizeCharge,
    required this.amountCollected,
    required this.instrumentNo,
    required this.dateMs,
    required this.paymentIds,
  });

  bool get hasExtras =>
      lpcAmount > 0 ||
      collectionCharge > 0 ||
      seizeCharge > 0 ||
      vasAmount > 0;
}

// ============================================================
// RAW PAYMENT RECORD (PRE-MERGE)
// ============================================================

/// One raw entry of installments[].payments[] /
/// vas[].payments[], holding only what the merge needs.
class _RawPayment {
  final String id;

  // Voucher grouping key: 'v:<voucher.id>' when the voucher id
  // exists, otherwise 'p:<payment.id>' so the record survives.
  final String groupKey;

  final String voucherId;
  final String voucherNo;
  final String voucherDescription;

  // Individual collected components. Each is read null-safely
  // from its optional backend component and is exactly 0.0
  // when that component is null/absent.
  final double emiAmount;
  final double vasAmount;
  final double lpcAmount;
  final double collectionCharge;
  final double seizeCharge;

  // First non-empty instrument number across this record's
  // components ('' when none carry one).
  final String instrumentNo;

  final List<String> componentDescriptions;

  // Existing fallback chain: voucher.createdAt -> record
  // createdAt -> component createdAt.
  final int? dateMs;

  const _RawPayment({
    required this.id,
    required this.groupKey,
    required this.voucherId,
    required this.voucherNo,
    required this.voucherDescription,
    required this.emiAmount,
    required this.vasAmount,
    required this.lpcAmount,
    required this.collectionCharge,
    required this.seizeCharge,
    required this.instrumentNo,
    required this.componentDescriptions,
    required this.dateMs,
  });

  /// Returns null when the record carries none of the five
  /// receipt components (nothing was received on it).
  static _RawPayment? parse(Map<String, dynamic> json) {
    final voucher = _asMap(json['voucher']);

    final emiComponent = _asMap(json['emi']);
    final vasComponent = _asMap(json['vasDue']);
    final lpcComponent = _asMap(json['lpcDue']);
    final chargesComponent =
        _asMap(json['collectionCharges']);
    final seizeComponent = _asMap(json['seizeCharges']);

    if (emiComponent == null &&
        vasComponent == null &&
        lpcComponent == null &&
        chargesComponent == null &&
        seizeComponent == null) {
      return null;
    }

    final componentDescriptions = <String>[
      _toStr(emiComponent?['description']),
      _toStr(vasComponent?['description']),
      _toStr(lpcComponent?['description']),
      _toStr(chargesComponent?['description']),
      _toStr(seizeComponent?['description']),
    ];

    final mainComponentDateMs = _toMillis(
          emiComponent?['createdAt'],
        ) ??
        _toMillis(vasComponent?['createdAt']) ??
        _toMillis(lpcComponent?['createdAt']) ??
        _toMillis(chargesComponent?['createdAt']) ??
        _toMillis(seizeComponent?['createdAt']);

    final id = _toStr(json['id']);
    final resolvedVoucherId = _toStr(voucher?['id']).trim();

    return _RawPayment(
      id: id,
      groupKey: resolvedVoucherId.isNotEmpty
          ? 'v:$resolvedVoucherId'
          : 'p:$id',
      voucherId: resolvedVoucherId,
      voucherNo: _toStr(voucher?['voucherNo']),
      voucherDescription:
          _toStr(voucher?['description']),
      emiAmount: _componentAmount(emiComponent),
      vasAmount: _componentAmount(vasComponent),
      lpcAmount: _componentAmount(lpcComponent),
      collectionCharge: _componentAmount(chargesComponent),
      seizeCharge: _componentAmount(seizeComponent),
      instrumentNo: _firstNonEmpty([
        emiComponent?['instrumentNo'],
        vasComponent?['instrumentNo'],
        lpcComponent?['instrumentNo'],
        chargesComponent?['instrumentNo'],
        seizeComponent?['instrumentNo'],
      ]),
      componentDescriptions: componentDescriptions,
      dateMs: _toMillis(voucher?['createdAt']) ??
          _toMillis(json['createdAt']) ??
          mainComponentDateMs,
    );
  }

  /// Null-safe amount reader for one optional receipt
  /// component.
  ///
  /// Equivalent to `component?.amount ?? 0.0`: a completely
  /// null component (backend returns null or omits the key)
  /// and a component with a null/invalid amount both resolve
  /// to exactly 0.0.
  static double _componentAmount(
    Map<String, dynamic>? component,
  ) {
    return _toDouble(component?['amount']);
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
