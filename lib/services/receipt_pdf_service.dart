// ============================================================
// RECEIPT PDF SERVICE
//
// Generates the VSF receipt PDF from a ReceiptModel.
//
// The ReceiptModel is the single source of truth shared with
// the on-screen preview, so the PDF can never show different
// amounts than the preview.
//
// Save vs Share:
//
//   saveToDownloads()  - writes the PDF as a real file into the
//     device's public Downloads folder through the native
//     "vsf_consumer/receipt_saver" method channel (Android
//     MediaStore.Downloads on API 29+, public Downloads dir on
//     API <= 28). Returns the visible location.
//
//   shareReceipt()     - hands the exact same bytes to the
//     system share sheet (WhatsApp etc.). Unchanged behaviour.
//
// Currency note: the built-in PDF base fonts do not contain
// the rupee glyph, so amounts are prefixed "Rs." here. The
// numeric grouping itself comes from ReceiptModel.formatAmount,
// identical to the preview.
// ============================================================

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receipt_model.dart';

class ReceiptPdfService {
  static const String _logoAsset = 'assets/vsf.png';

  static const MethodChannel _saverChannel = MethodChannel(
    'vsf_consumer/receipt_saver',
  );

  pw.MemoryImage? _logoImage;

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------

  /// Builds the PDF bytes for [receipt].
  Future<Uint8List> buildPdf(ReceiptModel receipt) async {
    final logo = await _loadLogo();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
        boldItalic: pw.Font.helveticaBoldOblique(),
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildReceipt(context, receipt, logo),
      ),
    );

    return doc.save();
  }

  /// Saves already-built [bytes] as `VSF_Receipt_<voucherNo>.pdf`
  /// into the device's public Downloads folder and returns the
  /// user-visible location (e.g. "Downloads/VSF_Receipt_x.pdf").
  ///
  /// Throws the underlying error when saving fails — callers must
  /// surface it instead of claiming success.
  Future<String> saveToDownloads(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final savedLocation = await _saverChannel.invokeMethod<String>(
        'savePdf',
        <String, dynamic>{
          'bytes': bytes,
          'fileName': fileName,
        },
      );

      if (savedLocation == null || savedLocation.isEmpty) {
        throw StateError('The PDF was saved but no location was returned.');
      }

      return savedLocation;
    } on MissingPluginException {
      // Non-Android platforms have no native saver; report
      // honestly instead of pretending the download happened.
      throw UnsupportedError(
        'Direct Downloads-folder saving is only supported on Android.',
      );
    }
  }

  /// Hands the exact same PDF bytes to the system share sheet
  /// (WhatsApp, Drive, etc.). Existing behaviour, unchanged.
  Future<bool> shareReceipt(Uint8List bytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// True when the current platform is Android (the platform with
  /// the native Downloads saver).
  bool get supportsDirectDownload =>
      defaultTargetPlatform.name.toLowerCase() == 'android';

  /// `VSF_Receipt_<voucherNo>.pdf` with filesystem-unsafe
  /// characters removed; voucherId is the fallback so two
  /// different receipts never share one file name.
  String fileNameFor(ReceiptModel receipt) {
    final rawId = receipt.voucherNo.trim().isNotEmpty
        ? receipt.voucherNo.trim()
        : receipt.voucherId.trim();

    final safeId = rawId.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '',
    );

    return 'VSF_Receipt_${safeId.isEmpty ? 'receipt' : safeId}.pdf';
  }

  // ------------------------------------------------------------
  // INTERNALS
  // ------------------------------------------------------------

  Future<pw.MemoryImage?> _loadLogo() async {
    if (_logoImage != null) {
      return _logoImage;
    }

    try {
      final data = await rootBundle.load(_logoAsset);

      _logoImage =
          pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // Logo asset unavailable -> header renders text only.
    }

    return _logoImage;
  }

  pw.Widget _buildReceipt(
    pw.Context context,
    ReceiptModel receipt,
    pw.MemoryImage? logo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(receipt, logo),

        _divider(),

        _buildDetails(receipt),

        _divider(),

        _buildItemsTable(receipt),

        pw.SizedBox(height: 18),

        _buildTotalBlock(receipt),

        pw.SizedBox(height: 24),

        _buildFooter(receipt),
      ],
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  pw.Widget _buildHeader(
    ReceiptModel receipt,
    pw.MemoryImage? logo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 52,
            height: 52,
            margin: const pw.EdgeInsets.only(right: 12),
            child: pw.Image(logo),
          ),

        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                ReceiptModel.companyName,
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),

              pw.SizedBox(height: 3),

              pw.Text(
                'Payment Receipt',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.indigo900,
                ),
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(4),
                ),
              ),
              child: pw.Text(
                ReceiptModel.copyLabel,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
            ),

            pw.SizedBox(height: 6),

            pw.Text(
              'CIN No.: ${receipt.cinNo}',
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RECEIPT DETAILS BLOCK
  // ------------------------------------------------------------

  pw.Widget _buildDetails(ReceiptModel receipt) {
    pw.Widget cell(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey600,
              ),
            ),

            pw.SizedBox(height: 1),

            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            cell('Date', receipt.dateText),
            cell('Voucher No.', receipt.voucherNo),
          ],
        ),
        pw.TableRow(
          children: [
            cell('Customer', receipt.customerName),
            cell('Vehicle', receipt.vehicleNumber),
          ],
        ),
        pw.TableRow(
          children: [
            cell('Instrument No.', receipt.instrumentNo),
            cell('Agreement No.', receipt.agreementNo),
          ],
        ),
        pw.TableRow(
          children: [
            cell('Agreement Date', receipt.agreementDateText),
            cell('Customer Phone', receipt.customerPhone),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PAYMENT TABLE
  // ------------------------------------------------------------

  pw.Widget _buildItemsTable(ReceiptModel receipt) {
    const headerStyle = pw.TextStyle(
      fontSize: 9,
      color: PdfColors.white,
    );

    final cellStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.grey900,
    );

    pw.Widget headerCell(String text,
        {pw.Alignment alignment = pw.Alignment.centerLeft}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        child: pw.Text(
          text,
          style: headerStyle,
        ),
      );
    }

    pw.Widget bodyCell(
      String text, {
      pw.Alignment alignment =
          pw.Alignment.centerLeft,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        child: pw.Text(
          text,
          style: bold
              ? pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                )
              : cellStyle,
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(34),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(2.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.indigo900,
          ),
          children: [
            headerCell('#', alignment: pw.Alignment.center),
            headerCell('Due Date'),
            headerCell('Desc'),
            headerCell('Amount',
                alignment: pw.Alignment.centerRight),
          ],
        ),

        // Line items — only applicable components appear.
        for (var i = 0; i < receipt.items.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd
                  ? PdfColors.grey100
                  : PdfColors.white,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Text(
                  '${i + 1}',
                  style: cellStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // Per-installment due dates are not carried on
              // the merged voucher transaction; shown as '--'.
              bodyCell('--'),
              bodyCell(receipt.items[i].label),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Rs. ${ReceiptModel.formatAmount(receipt.items[i].amount)}',
                    style: cellStyle,
                  ),
                ),
              ),
            ],
          ),

        // TOTAL row inside the table frame.
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Text(''),
            ),
            bodyCell('Total', bold: true),
            bodyCell(''),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Rs. ${ReceiptModel.formatAmount(receipt.totalAmount)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TOTAL EMPHASIS + FOOTER + SIGNATURES
  // ------------------------------------------------------------

  pw.Widget _buildTotalBlock(ReceiptModel receipt) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Amount Received',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.Text(
            'Rs. ${ReceiptModel.formatAmount(receipt.totalAmount)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(ReceiptModel receipt) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Payment Mode: ${receipt.paymentMode}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey800,
              ),
            ),
            pw.Text(
              'Cashier: ${receipt.cashier}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey800,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 42),

        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SizedBox(
              width: 170,
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 0.7,
                    color: PdfColors.grey600,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Customer Signature',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(
              width: 170,
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    height: 0.7,
                    color: PdfColors.grey600,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'For ${ReceiptModel.companyName}',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 26),

        pw.Center(
          child: pw.Text(
            'This is a System Generated Receipt',
            style: const pw.TextStyle(
              fontSize: 8.5,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _divider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      child: pw.Container(
        height: 0.7,
        color: PdfColors.grey400,
      ),
    );
  }
}
