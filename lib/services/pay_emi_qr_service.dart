import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/pay_emi_model.dart';

class PayEmiQrService {
  static const MethodChannel _saverChannel = MethodChannel(
    'vsf_consumer/qr_image_saver',
  );

  /// Saves the already-loaded QR image for [file] as a PNG into
  /// the device's Pictures folder (Android) and returns the
  /// user-visible location (e.g. "Pictures/VSF/VSF_Payment_QR_Gpay.png").
  ///
  /// No new network request is made: the caller passes the same
  /// [qrImageBytes] that are already displayed for the selected QR.
  static Future<String> saveQrImage({
    required PayEmiFile file,
    required Uint8List qrImageBytes,
  }) async {
    final cleanName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    final fileName = cleanName.isNotEmpty
        ? 'VSF_Payment_QR_$cleanName.png'
        : 'VSF_Payment_QR.png';

    try {
      final location = await _saverChannel.invokeMethod<String>(
        'saveImage',
        <String, dynamic>{
          'bytes': qrImageBytes,
          'fileName': fileName,
        },
      );

      if (location == null || location.isEmpty) {
        throw StateError('The QR image was saved but no location was returned.');
      }

      return location;
    } on MissingPluginException {
      throw UnsupportedError(
        'Saving the QR image to storage is only supported on Android.',
      );
    }
  }

  /// Builds a high quality payment slip PDF containing the QR image and metadata.
  static Future<Uint8List> buildQrPdf({
    required PayEmiFile file,
    required Uint8List? qrImageBytes,
  }) async {
    final doc = pw.Document();

    pw.ImageProvider? qrImage;
    if (qrImageBytes != null && qrImageBytes.isNotEmpty) {
      qrImage = pw.MemoryImage(qrImageBytes);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(28),
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'VSF Consumer',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF132FBA),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'EMI Payment QR Code',
                    style: const pw.TextStyle(
                      fontSize: 13,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  if (file.name.isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE8EDFB),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(12),
                        ),
                      ),
                      child: pw.Text(
                        file.name,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF132FBA),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 18),
                  ],
                  if (qrImage != null)
                    pw.Container(
                      width: 220,
                      height: 220,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(12),
                        ),
                      ),
                      child: pw.Image(qrImage, fit: pw.BoxFit.contain),
                    ),
                  pw.SizedBox(height: 18),
                  if (file.upiId.isNotEmpty) ...[
                    pw.Text(
                      'UPI ID: ${file.upiId}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF132FBA),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                  ],
                  if (file.paymentNumber.isNotEmpty) ...[
                    pw.Text(
                      'Payment Number: ${file.paymentNumber}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                  pw.Text(
                    'Open any UPI app and scan this QR code to complete your EMI payment.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Shares the QR code slip via system share sheet (WhatsApp, etc.).
  static Future<bool> shareQr({
    required PayEmiFile file,
    required Uint8List? qrImageBytes,
  }) async {
    try {
      final pdfBytes = await buildQrPdf(
        file: file,
        qrImageBytes: qrImageBytes,
      );

      final cleanName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
      final fileName = cleanName.isNotEmpty
          ? 'VSF_Payment_QR_$cleanName.pdf'
          : 'VSF_Payment_QR.pdf';

      return await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
        subject: 'VSF EMI Payment QR - ${file.name}',
      );
    } catch (_) {
      return false;
    }
  }
}
