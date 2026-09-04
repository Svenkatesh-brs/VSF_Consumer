import 'dart:typed_data';

import 'package:get/get.dart';

import '../models/pay_emi_model.dart';
import '../services/pay_emi_service.dart';

class PayEmiProvider extends GetxController {
  final PayEmiService _payEmiService;

  PayEmiProvider({required PayEmiService payEmiService})
    : _payEmiService = payEmiService;

  // ============================================================
  // STATE
  // ============================================================

  final Rxn<PayEmiModel> paymentInfo = Rxn<PayEmiModel>();

  final RxList<Uint8List> qrImages = <Uint8List>[].obs;
  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // GETTERS
  // ============================================================

  List<String> get paymentNumbers => paymentInfo.value?.paymentNumbers ?? [];

  List<String> get upiIds => paymentInfo.value?.upiIds ?? [];

  bool get hasQrImages => qrImages.isNotEmpty;
  bool get hasPaymentInfo => paymentInfo.value != null;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onReady() {
    super.onReady();
    loadPaymentInfo();
  }

  // ============================================================
  // LOAD PAYMENT INFORMATION
  // ============================================================

  Future<void> loadPaymentInfo() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final info = await _payEmiService.getPaymentInfo();

      paymentInfo.value = info;

      // ========================================================
      // LOAD QR IMAGE
      // ========================================================
      qrImages.clear();

      for (final fileId in info.files) {
        try {
          print('Loading QR: $fileId');

          final imageBytes = await _payEmiService.getQrImage(fileId);

          print('QR loaded: $fileId | bytes: ${imageBytes.length}');

          if (imageBytes.isNotEmpty) {
            qrImages.add(Uint8List.fromList(imageBytes));
          }
        } catch (e) {
          print('QR failed: $fileId');
          print('QR error: $e');
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
      paymentInfo.value = null;
      qrImages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadPaymentInfo();
  }
}
