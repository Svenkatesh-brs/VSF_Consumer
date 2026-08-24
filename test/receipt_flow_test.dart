// ============================================================
// RECEIPT FLOW VERIFICATION
//
// Feeds a trimmed copy of the REAL API payload shape through:
//
//   raw installments[].payments[] / vas[].payments[]
//     -> TransactionsModel.fromJson   (voucher merge)
//       -> LoanTransaction            (merged receipt)
//         -> ReceiptModel             (preview + PDF source)
//           -> ReceiptPdfService.buildPdf
//
// Verifies grouping, merged amounts, null handling, line-item
// rules (VAS only when > 0), totals and PDF/filename output.
// ============================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:vsf_consumer/models/receipt_model.dart';
import 'package:vsf_consumer/models/transactions_model.dart';
import 'package:vsf_consumer/services/receipt_pdf_service.dart';

Map<String, dynamic> _payment({
  required String id,
  required String voucherId,
  required String voucherNo,
  String createdAt = '2026-03-26T06:45:18.775Z',
  Map<String, dynamic>? emi,
  Map<String, dynamic>? lpcDue,
  Map<String, dynamic>? collectionCharges,
  Map<String, dynamic>? vasDue,
  Map<String, dynamic>? seizeCharges,
}) {
  return {
    'id': id,
    'status': true,
    'createdAt': createdAt,
    'updatedAt': createdAt,
    'voucher': {
      'id': voucherId,
      'voucherNo': voucherNo,
      'voucherType': 2,
      'status': 2,
      'createdAt': createdAt,
      'description': 'Test receipt $voucherNo',
    },
    'emi': emi,
    'lpcDue': lpcDue,
    'collectionCharges': collectionCharges,
    'vasDue': vasDue,
    'seizeCharges': seizeCharges,
  };
}

TransactionsModel _buildModel() {
  final loanJson = {
    'installments': [
      {
        'id': 'ins1',
        'dueDate': 1764892800000,
        'emi': 1804,
        'totalPaid': 1804,
        'totalLPCPaid': 395,
        'remainingAmount': 0,
        'lastPaymentDate': 1785834065438,
        'status': 'Paid',
        'lpcDue': 0,
        'payments': [
          _payment(
            id: 'p1',
            voucherId: 'v1',
            voucherNo: 'PRG565636940',
            emi: {'transactionType': 2, 'amount': 1804},
            lpcDue: {'transactionType': 3, 'amount': 395},
            collectionCharges: {
              'transactionType': 5,
              'amount': 500,
            },
          ),
          _payment(
            id: 'p2',
            voucherId: 'v1',
            voucherNo: 'PRG565636940',
            emi: {'transactionType': 2, 'amount': 1804},
            lpcDue: {'transactionType': 3, 'amount': 285},
          ),
          _payment(
            id: 'p3',
            voucherId: 'v1',
            voucherNo: 'PRG565636940',
            emi: {'transactionType': 2, 'amount': 1804},
            lpcDue: {'transactionType': 3, 'amount': 174},
          ),
          _payment(
            id: 'p4',
            voucherId: 'v1',
            voucherNo: 'PRG565636940',
            emi: {'transactionType': 2, 'amount': 1804},
            lpcDue: {'transactionType': 3, 'amount': 75},
          ),
          // Fifth EMI on the same voucher, LPC null -> 0.
          _payment(
            id: 'p5',
            voucherId: 'v1',
            voucherNo: 'PRG565636940',
            emi: {'transactionType': 2, 'amount': 1804},
            lpcDue: null,
          ),
        ],
      },
      {
        'id': 'ins2',
        'dueDate': 1791181800000,
        'emi': 1804,
        'totalPaid': 1196,
        'totalLPCPaid': 0,
        'remainingAmount': 608,
        'status': 'Partial',
        'lpcDue': 0,
        'payments': [
          // Closer-payment style record: charges only.
          _payment(
            id: 'p6',
            voucherId: 'v2',
            voucherNo: 'PRG585989275',
            createdAt: '2026-08-04T09:01:05.438Z',
            emi: null,
            lpcDue: null,
            collectionCharges: {
              'transactionType': 2,
              'amount': 9090,
              'instrumentNo': '545',
            },
            vasDue: null,
            seizeCharges: null,
          ),
          // Companion EMI record on the SAME voucher.
          _payment(
            id: 'p7',
            voucherId: 'v2',
            voucherNo: 'PRG585989275',
            createdAt: '2026-08-04T09:01:05.438Z',
            emi: {'transactionType': 2, 'amount': 267},
            lpcDue: null,
            collectionCharges: null,
            vasDue: null,
            seizeCharges: null,
          ),
          // Record with NO components at all -> dropped.
          _payment(
            id: 'p8',
            voucherId: 'vx',
            voucherNo: 'PRG000000000',
            createdAt: '2026-08-05T09:01:05.438Z',
          ),
        ],
      },
    ],
    'vas': [
      {
        'id': 'vas1',
        'loanId': 'loan1',
        'vasName': 'ADLC',
        'amount': 450,
        'payments': [
          _payment(
            id: 'pv1',
            voucherId: 'v3',
            voucherNo: 'PRG936248056',
            createdAt: '2025-11-04T00:00:00Z',
            vasDue: {'transactionType': 0, 'amount': 450},
          ),
        ],
      },
    ],
  };

  return TransactionsModel.fromJson(loanJson);
}

void main() {
  late TransactionsModel model;

  setUpAll(() {
    model = _buildModel();
  });

  test('merges raw payment fragments into ONE card per voucher',
      () {
    // 9 raw records parsed (p8 dropped), 3 merged vouchers.
    expect(model.totalCount, 3);

    expect(
      model.transactions.map((t) => t.voucherNo),
      ['PRG585989275', 'PRG565636940', 'PRG936248056'],
    );
  });

  test('charges-only record joins its voucher group (not dropped)',
      () {
    final v2 = model.transactions.first;

    expect(v2.voucherId, 'v2');
    expect(v2.paymentIds, ['p6', 'p7']);
    expect(v2.emiAmount, 267);
    expect(v2.collectionCharge, 9090);
    expect(v2.amountCollected, 9357);
    expect(v2.instrumentNo, '545');
    expect(v2.dateMs,
        DateTime.parse('2026-08-04T09:01:05.438Z')
            .millisecondsSinceEpoch);
  });

  test('multi-installment voucher sums every component', () {
    final v1 = model.transactions[1];

    expect(v1.paymentIds.length, 5);
    expect(v1.emiAmount, 1804 * 5); // 9020
    expect(v1.lpcAmount, 395 + 285 + 174 + 75 + 0); // 929
    expect(v1.collectionCharge, 500);
    expect(v1.vasAmount, 0);
    expect(v1.seizeCharge, 0);
    expect(v1.amountCollected, 10449);
    expect(v1.type, 'EMI Receipt');
  });

  test('VAS receipts come from vas[].payments[] via voucher key',
      () {
    final v3 = model.transactions[2];

    expect(v3.voucherNo, 'PRG936248056');
    expect(v3.vasAmount, 450);
    expect(v3.amountCollected, 450);
    expect(v3.type, 'VAS Receipt');
  });

  test('null components contribute 0.0 and never drop records',
      () {
    // p5 (lpcDue: null) still counted inside v1 above.
    final v1 = model.transactions[1];

    expect(v1.lpcAmount, 929);
    // p6 (all except charges null) fully present in v2.
    final v2 = model.transactions.first;

    expect(v2.emiAmount, greaterThan(0));
  });

  test('receipt line items follow the reference rules', () {
    final v1Receipt = ReceiptModel.fromTransaction(
      model.transactions[1],
      dateText: '26 Mar 2026',
      customerName: 'POTAGALLA CHENNAIAH',
      vehicleNumber: 'TS06FB9579',
      agreementNo: '2TG-RV-26-00093',
      agreementDateText: '01 Dec 2025',
    );

    // VAS == 0 -> NO VAS row; only applicable rows appear.
    expect(
      v1Receipt.items.map((item) => item.label).toList(),
      ['EMI', 'LPC', 'Collection Charges'],
    );

    expect(v1Receipt.totalAmount, 10449);
    expect(
      v1Receipt.items.fold<double>(0, (s, i) => s + i.amount),
      v1Receipt.totalAmount,
    );

    // VAS > 0 -> VAS appears as a normal line item.
    const vasTransaction = LoanTransaction(
      voucherId: 'v4',
      voucherNo: 'PRG111111111',
      description: '',
      type: 'Mixed Receipt',
      emiAmount: 9020,
      vasAmount: 450,
      lpcAmount: 929,
      collectionCharge: 500,
      seizeCharge: 0,
      amountCollected: 10899,
      instrumentNo: '',
      dateMs: null,
      paymentIds: [],
    );

    final mixedReceipt = ReceiptModel.fromTransaction(
      vasTransaction,
      dateText: '01 Jan 2026',
    );

    expect(
      mixedReceipt.items.map((item) => item.label).toList(),
      ['EMI', 'LPC', 'Collection Charges', 'VAS'],
    );

    expect(mixedReceipt.totalAmount, 10899);
  });

  test('shared formatter renders identical preview/PDF strings',
      () {
    expect(ReceiptModel.formatAmount(10449), '10,449');
    expect(ReceiptModel.formatAmount(9020), '9,020');
    expect(ReceiptModel.formatAmount(929), '929');
    expect(ReceiptModel.formatAmount(10899), '10,899');
    expect(ReceiptModel.formatAmount(450), '450');
  });

  test('PDF builds per receipt with unique file names', () async {
    final service = ReceiptPdfService();

    final receiptA = ReceiptModel.fromTransaction(
      model.transactions[1],
      dateText: '26 Mar 2026',
    );

    final receiptB = ReceiptModel.fromTransaction(
      model.transactions.first,
      dateText: '04 Aug 2026',
    );

    final bytesA = await service.buildPdf(receiptA);
    final bytesB = await service.buildPdf(receiptB);

    expect(bytesA, isNotEmpty);
    expect(bytesB, isNotEmpty);
    expect(bytesA, isNot(equals(bytesB)));

    expect(service.fileNameFor(receiptA),
        'VSF_Receipt_PRG565636940.pdf');
    expect(service.fileNameFor(receiptB),
        'VSF_Receipt_PRG585989275.pdf');
  });
}
