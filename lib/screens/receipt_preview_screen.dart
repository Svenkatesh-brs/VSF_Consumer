// ============================================================
// RECEIPT PREVIEW SCREEN
//
// Shows ONE voucher receipt for a tapped transaction card.
//
// The receipt is built ONCE from the merged LoanTransaction
// (plus the already-loaded loan/customer data of the shared
// LoanDashboardProvider — no additional API call) and the SAME
// ReceiptModel instance feeds both this preview and the
// generated PDF, so both always show identical amounts.
// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/receipt_model.dart';
import '../models/transactions_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../services/receipt_pdf_service.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/app_submit_button.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key});

  @override
  State<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState
    extends State<ReceiptPreviewScreen> {
  final LoanDashboardProvider controller =
      Get.find<LoanDashboardProvider>();

  final ReceiptPdfService _pdfService = ReceiptPdfService();

  bool _isDownloading = false;

  // Built once; shared by preview + PDF.
  late final ReceiptModel receipt;

  LoanTransaction? _resolveTransaction() {
    final arguments = Get.arguments;

    if (arguments is LoanTransaction) {
      return arguments;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    final transaction =
        _resolveTransaction() ?? _fallbackTransaction();

    receipt = _buildReceipt(transaction);
  }

  // ------------------------------------------------------------
  // RECEIPT ASSEMBLY (single source of truth)
  // ------------------------------------------------------------

  LoanTransaction _fallbackTransaction() {
    return const LoanTransaction(
      voucherId: '',
      voucherNo: '',
      description: '',
      type: '',
      emiAmount: 0,
      vasAmount: 0,
      lpcAmount: 0,
      collectionCharge: 0,
      seizeCharge: 0,
      amountCollected: 0,
      instrumentNo: '',
      dateMs: null,
      paymentIds: [],
    );
  }

  ReceiptModel _buildReceipt(
    LoanTransaction transaction,
  ) {
    final details = controller.loanDetails.value;
    final dashboard = controller.dashboard.value;
    final borrower = details?.borrower;

    return ReceiptModel.fromTransaction(
      transaction,
      dateText:
          controller.formatDateMs(transaction.dateMs),
      customerName: _firstNonEmpty([
        borrower?.name,
        dashboard?.borrowerName,
      ]),
      customerPhone: borrower?.phone ?? '',
      vehicleNumber: _firstNonEmpty([
        details?.asset?.registrationNumber,
        dashboard?.vehicleNumber,
      ]),
      agreementNo: _firstNonEmpty([
        details?.loanNo,
        dashboard?.loanNo,
      ]),
      agreementDateText: controller
          .formatDateMs(details?.agreementDateMs),
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  // ============================================================
  // BACK NAVIGATION
  // ============================================================

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();

    Get.back();
  }

  // ============================================================
  // DOWNLOAD PDF
  //
  // Builds the PDF once and saves it as a real file into the
  // device's public Downloads folder via the native saver.
  // Failures surface their actual error — never a fake success.
  // ============================================================

  Future<void> _downloadPdf() async {
    if (_isDownloading) {
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final bytes = await _pdfService.buildPdf(receipt);
      final fileName = _pdfService.fileNameFor(receipt);

      final savedLocation = await _pdfService.saveToDownloads(
        bytes,
        fileName,
      );

      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Receipt downloaded successfully',
        '$fileName saved to $savedLocation',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor:
            Colors.white.withValues(alpha: 0.96),
        colorText: AppColors.lightBlue,
        duration: const Duration(seconds: 3),
      );
    } on UnsupportedError {
      // Platform without the native saver (e.g. iOS during
      // development): fall back to the share sheet and say so
      // instead of claiming a download happened.
      await _sharePdf();

      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Receipt',
        'Direct Downloads saving is only supported on '
            'Android. The receipt was opened in the share '
            'sheet instead.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        backgroundColor: Colors.white,
        colorText: Colors.black87,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Download failed',
        _describeError(error),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        backgroundColor: Colors.white,
        colorText: Colors.black87,
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _describeError(Object error) {
    if (error is Exception || error is Error) {
      final message = error.toString().trim();

      if (message.isNotEmpty && message != error.runtimeType.toString()) {
        return message;
      }
    }

    return 'The receipt could not be saved to your device.';
  }

  // ============================================================
  // SHARE PDF
  //
  // Separate action: hands the exact same PDF bytes to the
  // system share sheet (WhatsApp etc.). Unchanged behaviour.
  // ============================================================

  Future<void> _sharePdf() async {
    try {
      final bytes = await _pdfService.buildPdf(receipt);

      await _pdfService.shareReceipt(
        bytes,
        _pdfService.fileNameFor(receipt),
      );
    } catch (_) {
      Get.snackbar(
        'Receipt',
        'Unable to open the share sheet. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        backgroundColor: Colors.white,
        colorText: Colors.black87,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),

              Expanded(child: _buildScrollableReceipt()),

              _buildDownloadBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER (matches the app's screen header pattern)
  // ------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _goBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: AppColors.lightBlue,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  receipt.voucherNo.isEmpty
                      ? 'Voucher --'
                      : 'Voucher ${receipt.voucherNo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SCROLLABLE RECEIPT PAPER
  // ------------------------------------------------------------

  Widget _buildScrollableReceipt() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _receiptHeader(),

            _receiptDivider(),

            _receiptDetails(),

            _receiptDivider(),

            _receiptItemsTable(),

            const SizedBox(height: 14),

            _receiptTotalBlock(),

            const SizedBox(height: 22),

            _receiptFooter(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RECEIPT SECTIONS (mirrors the reference layout)
  // ------------------------------------------------------------

  Widget _receiptHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/vsf.png',
            width: 46,
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.lightBlue
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.lightBlue,
                size: 22,
              ),
            ),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                ReceiptModel.companyName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightBlue,
                ),
              ),

              const SizedBox(height: 3),

              const Text(
                'Payment Receipt',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.lightBlue
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                ReceiptModel.copyLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.lightBlue,
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'CIN No.: ${receipt.cinNo}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: Colors.black.withValues(alpha: 0.12),
      ),
    );
  }

  Widget _detailCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Colors.black.withValues(alpha: 0.40),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value.isEmpty ? '--' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xDD000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptDetails() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailCell(
                'Date',
                receipt.dateText,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _detailCell(
                'Voucher No.',
                receipt.voucherNo,
              ),
            ),
          ],
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailCell(
                'Customer',
                receipt.customerName,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _detailCell(
                'Vehicle',
                receipt.vehicleNumber,
              ),
            ),
          ],
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailCell(
                'Instrument No.',
                receipt.instrumentNo,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _detailCell(
                'Agreement No.',
                receipt.agreementNo,
              ),
            ),
          ],
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _detailCell(
                'Agreement Date',
                receipt.agreementDateText,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _detailCell(
                'Customer Phone',
                receipt.customerPhone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tableHeaderText(String text,
      {bool right = false}) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _tableCellText(
    String text, {
    bool bold = false,
    bool right = false,
    Color? color,
  }) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 11,
        fontWeight:
            bold ? FontWeight.w800 : FontWeight.w500,
        color: color ?? const Color(0xDD000000),
      ),
    );
  }

  Widget _receiptItemsTable() {
    const headerColor = AppColors.lightBlue;

    final rows = <TableRow>[
      TableRow(
        decoration:
            const BoxDecoration(color: headerColor),
        children: [
          _tablePadding(_tableHeaderText('#')),
          _tablePadding(_tableHeaderText('Due Date')),
          _tablePadding(_tableHeaderText('Desc')),
          _tablePadding(
            _tableHeaderText('Amount', right: true),
          ),
        ],
      ),

      // Line items — only applicable components appear.
      for (var i = 0; i < receipt.items.length; i++)
        TableRow(
          decoration: BoxDecoration(
            color: i.isOdd
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.white,
          ),
          children: [
            _tablePadding(
              _tableCellText('${i + 1}'),
            ),
            // Per-installment due dates are not carried on the
            // merged voucher transaction.
            _tablePadding(_tableCellText('--')),
            _tablePadding(
              _tableCellText(receipt.items[i].label),
            ),
            _tablePadding(
              _tableCellText(
                '₹${ReceiptModel.formatAmount(receipt.items[i].amount)}',
                right: true,
              ),
            ),
          ],
        ),

      // TOTAL row inside the table frame.
      TableRow(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        children: [
          _tablePadding(const Text('')),
          _tablePadding(
            _tableCellText('Total', bold: true),
          ),
          _tablePadding(const Text('')),
          _tablePadding(
            _tableCellText(
              '₹${ReceiptModel.formatAmount(receipt.totalAmount)}',
              bold: true,
              right: true,
              color: AppColors.lightBlue,
            ),
          ),
        ],
      ),
    ];

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(4),
        3: FlexColumnWidth(2.6),
      },
      border: TableBorder.all(
        color: Colors.black.withValues(alpha: 0.25),
        width: 0.6,
      ),
      defaultVerticalAlignment:
          TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _tablePadding(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: child,
    );
  }

  Widget _receiptTotalBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount Received',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.lightBlue,
            ),
          ),

          Flexible(
            child: Text(
              '₹${ReceiptModel.formatAmount(receipt.totalAmount)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatureArea(String label,
      {bool alignRight = false}) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.8,
            color: Colors.black.withValues(alpha: 0.35),
          ),

          const SizedBox(height: 5),

          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Mode: ${receipt.paymentMode}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),

            Text(
              'Cashier: ${receipt.cashier}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
        ),

        const SizedBox(height: 38),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            _signatureArea('Customer Signature'),

            _signatureArea(
              'For ${ReceiptModel.companyName}',
              alignRight: true,
            ),
          ],
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            'This is a System Generated Receipt',
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // DOWNLOAD BAR
  //
  // Primary action saves into Downloads; the icon button keeps
  // the original share-sheet flow available separately.
  // ------------------------------------------------------------

  Widget _buildDownloadBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Share',
              onPressed: _sharePdf,
              icon: const Icon(
                Icons.share_outlined,
                size: 21,
                color: AppColors.lightBlue,
              ),
            ),
          ),

          Expanded(
            child: AppSubmitButton(
              label: 'Download PDF',
              isLoading: _isDownloading,
              onTap: _downloadPdf,
            ),
          ),
        ],
      ),
    );
  }
}
