// ============================================================
// RECEIPT VIEW MODEL
//
// ONE VOUCHER = ONE RECEIPT.
//
// Built from an already-merged LoanTransaction (source of truth
// for every amount) plus the loan/customer information the
// Consumer app has already loaded via LoanDashboardProvider
// (LoanDetailsModel / LoanDashboardModel). No additional API
// call is made.
//
// The SAME ReceiptModel instance is rendered by the on-screen
// receipt preview AND by the generated PDF, so both can never
// show different numbers.
//
// Nothing is invented: fields that are not present in the
// existing app data resolve to '--'.
// ============================================================

import 'transactions_model.dart';

class ReceiptModel {
  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  static const String companyName =
      'Vishnu Sai Finance Corporation';

  static const String copyLabel = 'Customer Copy';

  // Not provided by any current API/model; shown as '--'.
  final String cinNo;

  // ------------------------------------------------------------
  // RECEIPT DETAILS
  // ------------------------------------------------------------

  final String voucherId;
  final String voucherNo;

  // Pre-formatted "dd MMM yyyy" text ('--' when unavailable).
  final String dateText;

  final String customerName;
  final String customerPhone;
  final String vehicleNumber;
  final String instrumentNo;

  // Agreement number/date from the already-loaded loan details
  // (loanNo / agreementDate of the same loan response).
  final String agreementNo;
  final String agreementDateText;

  // ------------------------------------------------------------
  // PAYMENT COMPONENTS
  // ------------------------------------------------------------

  /// Applicable line items only (amount > 0), in reference
  /// order: EMI, LPC, Collection Charges, VAS, Seize Charges.
  final List<ReceiptLineItem> items;

  /// emiAmount + lpcAmount + collectionCharge + vasAmount +
  /// seizeCharge, taken verbatim from the merged transaction.
  final double totalAmount;

  // ------------------------------------------------------------
  // FOOTER CONTEXT (not available in current API -> '--')
  // ------------------------------------------------------------

  final String paymentMode;
  final String cashier;

  const ReceiptModel({
    required this.cinNo,
    required this.voucherId,
    required this.voucherNo,
    required this.dateText,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleNumber,
    required this.instrumentNo,
    required this.agreementNo,
    required this.agreementDateText,
    required this.items,
    required this.totalAmount,
    required this.paymentMode,
    required this.cashier,
  });

  /// Builds the receipt from the merged transaction plus the
  /// already-loaded dashboard/details data.
  ///
  /// [dateText] / [agreementDateText] must be formatted by the
  /// caller using the shared provider formatter so the preview
  /// and the PDF show identical text.
  factory ReceiptModel.fromTransaction(
    LoanTransaction transaction, {
    required String dateText,
    String customerName = '',
    String customerPhone = '',
    String vehicleNumber = '',
    String agreementNo = '',
    String agreementDateText = '',
  }) {
    final items = <ReceiptLineItem>[
      if (transaction.emiAmount > 0)
        ReceiptLineItem(
            label: 'EMI', amount: transaction.emiAmount),
      if (transaction.lpcAmount > 0)
        ReceiptLineItem(
            label: 'LPC', amount: transaction.lpcAmount),
      if (transaction.collectionCharge > 0)
        ReceiptLineItem(
          label: 'Collection Charges',
          amount: transaction.collectionCharge,
        ),
      if (transaction.vasAmount > 0)
        ReceiptLineItem(
            label: 'VAS', amount: transaction.vasAmount),
      if (transaction.seizeCharge > 0)
        ReceiptLineItem(
          label: 'Seize Charges',
          amount: transaction.seizeCharge,
        ),
    ];

    return ReceiptModel(
      cinNo: _unavailable,
      voucherId: transaction.voucherId,
      voucherNo: transaction.voucherNo,
      dateText: _textOrDash(dateText),
      customerName: _textOrDash(customerName),
      customerPhone: _textOrDash(customerPhone),
      vehicleNumber: _textOrDash(vehicleNumber),
      instrumentNo: _textOrDash(transaction.instrumentNo),
      agreementNo: _textOrDash(agreementNo),
      agreementDateText: _textOrDash(agreementDateText),
      items: items,
      totalAmount: transaction.amountCollected,
      paymentMode: _unavailable,
      cashier: _unavailable,
    );
  }

  // ------------------------------------------------------------
  // SHARED FORMATTING (preview + PDF render identical strings)
  // ------------------------------------------------------------

  static const String _unavailable = '--';

  static String _textOrDash(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? _unavailable : trimmed;
  }

  /// Indian digit grouping without currency symbol
  /// (e.g. 10449 -> "10,449"). Shared by the preview and the
  /// PDF so both always display the same characters after their
  /// own currency prefix.
  static String formatAmount(double amount) {
    final rounded = amount.round().toString();

    final negative = rounded.startsWith('-');
    final digits =
        negative ? rounded.substring(1) : rounded;

    final buffer = StringBuffer();

    if (digits.length <= 3) {
      buffer.write(digits);
    } else {
      final lastThree = digits.substring(digits.length - 3);
      final rest = digits.substring(0, digits.length - 3);

      final grouped = <String>[];
      for (var i = rest.length; i > 0; i -= 2) {
        grouped.add(rest.substring(i - 2 < 0 ? 0 : i - 2, i));
      }

      buffer
        ..write(grouped.reversed.join(','))
        ..write(',')
        ..write(lastThree);
    }

    return negative ? '-$buffer' : buffer.toString();
  }
}

// ============================================================
// SINGLE RECEIPT LINE ITEM
// ============================================================

class ReceiptLineItem {
  final String label;
  final double amount;

  const ReceiptLineItem({
    required this.label,
    required this.amount,
  });
}
