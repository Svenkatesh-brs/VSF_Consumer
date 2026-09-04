import 'dart:typed_data';

import 'package:get/get.dart';

import '../models/pay_emi_model.dart';
import '../services/pay_emi_service.dart';

class PayEmiProvider extends GetxController {
  final PayEmiService _payEmiService;

  PayEmiProvider({
    required PayEmiService payEmiService,
  }) : _payEmiService = payEmiService;

  // ============================================================
  // STATE
  // ============================================================

  final Rxn<PayEmiModel> paymentInfo = Rxn<PayEmiModel>();

  final Rxn<Uint8List> qrImage = Rxn<Uint8List>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // GETTERS
  // ============================================================

  List<String> get paymentNumbers =>
      paymentInfo.value?.paymentNumbers ?? [];

  List<String> get upiIds =>
      paymentInfo.value?.upiIds ?? [];

  bool get hasQrImage =>
      qrImage.value != null && qrImage.value!.isNotEmpty;

  bool get hasPaymentInfo =>
      paymentInfo.value != null;

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

      if (info.files.isNotEmpty) {
        final fileId = info.files.first;

        final imageBytes = await _payEmiService.getQrImage(fileId);

        qrImage.value = Uint8List.fromList(imageBytes);
      } else {
        qrImage.value = null;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      paymentInfo.value = null;
      qrImage.value = null;
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