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

  List<String> get paymentNumbers => paymentInfo.value?.paymentNumbers ?? [];

  List<String> get upiIds => paymentInfo.value?.upiIds ?? [];

  List<PayEmiFile> get files => paymentInfo.value?.files ?? [];

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

      paymentInfo.value = info;

      // ========================================================
      // LOAD QR IMAGES
      //
      // Each file's QR image is loaded using its own `did`.
      // A failed QR is stored as null so its index still matches
      // the corresponding PayEmiFile, keeping the QR, its name,
      // its UPI ID and the swipe position in sync.
      // ========================================================
      qrImages.clear();

      for (final file in info.files) {
        try {
          final imageBytes = await _payEmiService.getQrImage(file.did);

          if (imageBytes.isNotEmpty) {
            qrImages.add(Uint8List.fromList(imageBytes));
          } else {
            qrImages.add(null);
          }
        } catch (_) {
          qrImages.add(null);
        }
      }

      if (selectedQrIndex.value >= 0 && selectedQrIndex.value >= files.length) {
        selectedQrIndex.value = files.isEmpty ? 0 : files.length - 1;
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
