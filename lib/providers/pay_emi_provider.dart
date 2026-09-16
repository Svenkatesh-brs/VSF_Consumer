import 'dart:typed_data';

import 'package:get/get.dart';

import '../models/pay_emi_model.dart';
import '../services/pay_emi_service.dart';

class PayEmiProvider extends GetxController {
  final PayEmiService _payEmiService;

  PayEmiProvider({required PayEmiService payEmiService})
      // ignore: prefer_initializing_formals
      : _payEmiService = payEmiService;

  // ============================================================
  // STATE
  // ============================================================

  final Rxn<PayEmiModel> paymentInfo = Rxn<PayEmiModel>();

  // QR image at index N always corresponds to the PayEmiFile at
  // index N in [files]. Failures are stored as null so the index
  // correspondence is never broken.
  final RxList<Uint8List?> qrImages = <Uint8List?>[].obs;
  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // Index of the currently selected QR inside the swipeable
  // carousel. Keeps the selected QR and its metadata in sync.
  final RxInt selectedQrIndex = 0.obs;

  // ============================================================
  // GETTERS
  // ============================================================

  List<String> get contactNumbers => paymentInfo.value?.contactNumbers ?? [];

  List<PayEmiFile> get files => paymentInfo.value?.files ?? [];

  PayEmiFile? get selectedFile {
    final list = files;
    if (list.isEmpty) return null;
    final index = selectedQrIndex.value;
    if (index >= 0 && index < list.length) {
      return list[index];
    }
    return list.first;
  }

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
    await _loadPaymentInfo(showLoading: true);
  }

  // ============================================================
  // REFRESH PAYMENT INFORMATION
  //
  // Same API call and data updates as loadPaymentInfo, but keeps
  // the current content on screen while the RefreshIndicator
  // provides the progress feedback. Used for pull-to-refresh.
  // ============================================================

  Future<void> refreshPaymentInfo() async {
    await _loadPaymentInfo(showLoading: false);
  }

  Future<void> _loadPaymentInfo({required bool showLoading}) async {
    if (isLoading.value) {
      return;
    }

    if (showLoading) {
      isLoading.value = true;
      errorMessage.value = '';
    }

    try {
      final info = await _payEmiService.getPaymentInfo();

      // ========================================================
      // LOAD QR IMAGES
      //
      // Pre-allocate loadedImages matching info.files length.
      // Each file's QR image is loaded using its own `did`.
      // A failed QR is stored as null at its exact index so its
      // position strictly matches the corresponding PayEmiFile,
      // keeping the QR, name, UPI ID, payment number and swipe
      // position synchronized.
      // ========================================================
      final loadedImages = List<Uint8List?>.filled(info.files.length, null);

      for (int i = 0; i < info.files.length; i++) {
        final file = info.files[i];
        try {
          if (file.did.trim().isNotEmpty) {
            final imageBytes = await _payEmiService.getQrImage(file.did);
            if (imageBytes.isNotEmpty) {
              loadedImages[i] = Uint8List.fromList(imageBytes);
            }
          }
        } catch (_) {
          loadedImages[i] = null;
        }
      }

      paymentInfo.value = info;
      qrImages.assignAll(loadedImages);

      if (selectedQrIndex.value >= info.files.length) {
        selectedQrIndex.value = info.files.isEmpty ? 0 : info.files.length - 1;
      }
    } catch (e) {
      if (showLoading) {
        errorMessage.value = e.toString();
        paymentInfo.value = null;
        qrImages.clear();
        selectedQrIndex.value = 0;
      }
    } finally {
      if (showLoading) {
        isLoading.value = false;
      }
    }
  }

  // ============================================================
  // SELECTED QR INDEX
  // ============================================================

  void selectQrIndex(int index) {
    if (index >= 0 && index < files.length) {
      selectedQrIndex.value = index;
    }
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retry() async {
    await loadPaymentInfo();
  }
}
