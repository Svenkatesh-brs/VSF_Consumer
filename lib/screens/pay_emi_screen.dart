import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/pay_emi_provider.dart';
import '../models/pay_emi_model.dart';
import '../services/pay_emi_qr_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/common/app_card.dart';

class PayEmiScreen extends GetView<PayEmiProvider> {
  const PayEmiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: Obx(() => _buildBody(context))),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.lightBlue,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return _buildLoadingState();
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorState();
    }

    if (!controller.hasPaymentInfo) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: controller.refreshPaymentInfo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQrCard(context),
            const SizedBox(height: 22),
            _buildContactNumbersSection(),
            const SizedBox(height: 22),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QR CARD
  // ============================================================

  Widget _buildQrCard(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tintColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.lightBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'scan_pay'.tr,
                      style: AppTheme.style.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'scan_qr_upi'.tr,
                      style: AppTheme.style.copyWith(
                        fontSize: 11.5,
                        color: AppColors.hint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQrImage(context),
        ],
      ),
    );
  }

  Widget _buildQrImage(BuildContext context) {
    final files = controller.files;

    if (files.isEmpty) {
      return SizedBox(
        width: 230,
        height: 230,
        child: _buildQrUnavailable(),
      );
    }

    if (files.length == 1) {
      final image = controller.qrImages.isEmpty
          ? null
          : controller.qrImages.first;

      return Column(
        children: [
          if (files.first.name.trim().isNotEmpty) ...[
            _buildProviderBadge(files.first.name.trim()),
            const SizedBox(height: 12),
          ],
          _buildQrImageFrame(
            image: image,
            onTap: image != null && image.isNotEmpty
                ? () => _showEnlargedQrDialog(context, files.first, image)
                : null,
          ),
          const SizedBox(height: 14),
          _buildQrMetadata(files.first),
        ],
      );
    }

    return Column(
      children: [
        Obx(() {
          final index = controller.selectedQrIndex.value;
          final currentFile = index < files.length ? files[index] : files.first;
          final name = currentFile.name.trim();
          if (name.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildProviderBadge(name),
          );
        }),
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: files.length,
            controller: PageController(
              viewportFraction: 0.88,
              initialPage: controller.selectedQrIndex.value.clamp(
                0,
                files.length - 1,
              ),
            ),
            onPageChanged: controller.selectQrIndex,
            itemBuilder: (context, index) {
              final image = index < controller.qrImages.length
                  ? controller.qrImages[index]
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildQrImageFrame(
                  image: image,
                  onTap: image != null && image.isNotEmpty
                      ? () => _showEnlargedQrDialog(
                            context,
                            files[index],
                            image,
                          )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () {
            final index = controller.selectedQrIndex.value;
            final currentFile =
                index < files.length ? files[index] : files.first;
            return _buildQrMetadata(currentFile);
          },
        ),
        const SizedBox(height: 10),
        Text(
          'swipe_qr_codes'.trParams({'count': '${files.length}'}),
          style: AppTheme.style.copyWith(fontSize: 11.5, color: AppColors.hint),
        ),
      ],
    );
  }

  Widget _buildProviderBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tintColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        name,
        style: AppTheme.style.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.lightBlue,
        ),
      ),
    );
  }

  Widget _buildQrImageFrame({
    required Uint8List? image,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 230,
          height: 230,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.tintColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightBlack.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image == null || image.isEmpty
                      ? _buildQrUnavailable()
                      : Image.memory(
                          image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _buildQrUnavailable(),
                        ),
                ),
              ),
              if (image != null && image.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.tintColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: AppColors.lightBlue,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED QR METADATA
  // ============================================================

  Widget _buildQrMetadata(PayEmiFile file) {
    final upi = file.upiId.trim();
    final paymentNumber = file.paymentNumber.trim();

    if (upi.isEmpty && paymentNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tintColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upi.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.secondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'upi_id'.tr,
                        style: AppTheme.style.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.hint,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        upi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.style.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildCopyButton(upi),
              ],
            ),
          if (upi.isNotEmpty && paymentNumber.isNotEmpty)
            Divider(
              height: 16,
              color: AppColors.inputBorder.withValues(alpha: 0.35),
            ),
          if (paymentNumber.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.secondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'payment_number'.tr,
                        style: AppTheme.style.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.hint,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        paymentNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.style.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildCopyButton(paymentNumber),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: isEnabled
          ? backgroundColor
          : AppColors.tintColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      elevation: isEnabled ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isEnabled ? foregroundColor : AppColors.hint,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTheme.style.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? foregroundColor : AppColors.hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ENLARGED FULLSCREEN QR DIALOG
  // ============================================================

  void _showEnlargedQrDialog(
    BuildContext context,
    PayEmiFile file,
    Uint8List image,
  ) {
    showDialog(
      context: context,
      barrierColor: AppColors.lightBlack.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tintColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.lightBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name.isNotEmpty
                                ? file.name
                                : 'payment_qr_code'.tr,
                            style: AppTheme.style.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightBlue,
                            ),
                          ),
                          Text(
                            'pinch_zoom_qr'.tr,
                            style: AppTheme.style.copyWith(
                              fontSize: 10.5,
                              color: AppColors.hint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.hint,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 290,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.tintColor,
                      width: 1.5,
                    ),
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: Image.memory(
                      image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildQrMetadata(file),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSecondaryActionButton(
                        icon: Icons.download_rounded,
                        label: 'save_qr'.tr,
                        backgroundColor: AppColors.buttonStart,
                        foregroundColor: AppColors.lightBlue,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _handleSaveQr(file, image);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSecondaryActionButton(
                        icon: Icons.share_rounded,
                        label: 'share_qr'.tr,
                        backgroundColor: AppColors.buttonEnd,
                        foregroundColor: AppColors.white,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          _handleShareQr(file, image);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION HANDLERS
  // ============================================================

  Future<void> _handleSaveQr(PayEmiFile file, Uint8List image) async {
    try {
      final location = await PayEmiQrService.saveQrImage(
        file: file,
        qrImageBytes: image,
      );

      Get.snackbar(
        'qr_code_saved'.tr,
        'saved_to'.trParams({'location': location}),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.lightBlue,
        colorText: AppColors.white,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        duration: const Duration(seconds: 3),
      );
    } catch (_) {
      Get.snackbar(
        'save_failed'.tr,
        'unable_save_qr'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.lightBlue,
        colorText: AppColors.white,
      );
    }
  }

  Future<void> _handleShareQr(PayEmiFile file, Uint8List image) async {
    final shared = await PayEmiQrService.shareQr(
      file: file,
      qrImageBytes: image,
    );

    if (!shared) {
      Get.snackbar(
        'share'.tr,
        'unable_open_share'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.lightBlue,
        colorText: AppColors.white,
      );
    }
  }

  Widget _buildQrUnavailable() {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        color: AppColors.tintColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_rounded, color: AppColors.hint, size: 64),
          const SizedBox(height: 10),
          Text(
            'qr_unavailable'.tr,
            style: AppTheme.style.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.hint,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACT NUMBERS
  // ============================================================

  Widget _buildContactNumbersSection() {
    final numbers = controller.contactNumbers;

    if (numbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildPaymentDetailSection(
      title: 'contact_numbers'.tr,
      subtitle: 'contact_numbers_support'.tr,
      icon: Icons.support_agent_rounded,
      children: [
        ...numbers.asMap().entries.map(
          (entry) => _buildContactNumberItem(
            value: entry.value,
            label: 'contact_number'.tr,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT DETAIL SECTION
  // ============================================================

  Widget _buildPaymentDetailSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.tintColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.lightBlue, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.style.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.style.copyWith(
                      fontSize: 11.5,
                      color: AppColors.hint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 22,
                    color: AppColors.inputBorder.withValues(alpha: 0.35),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTACT NUMBER ACTIONS
  // ============================================================

  Widget _buildContactNumberItem({
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.tintColor.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: AppColors.secondary,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.style.copyWith(
                  fontSize: 10.5,
                  color: AppColors.hint,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.style.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildCallButton(value),
        const SizedBox(width: 8),
        _buildCopyButton(value),
      ],
    );
  }

  Widget _buildCallButton(String value) {
    return Material(
      color: AppColors.tintColor,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _callContactNumber(value),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.call_rounded, color: AppColors.lightBlue, size: 18),
        ),
      ),
    );
  }

  Future<void> _callContactNumber(String value) async {
    final dialableNumber = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (dialableNumber.isEmpty) {
      return;
    }

    try {
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: dialableNumber),
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return;
      }
    } catch (_) {
      // Display the same message for a launcher error or unavailable dialer.
    }

    if (Get.context != null) {
      Get.snackbar(
        'call_unavailable'.tr,
        'unable_open_dialer'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.lightBlue,
        colorText: AppColors.white,
      );
    }
  }

  Widget _buildCopyButton(String value) {
    return Material(
      color: AppColors.tintColor,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _copyToClipboard(value),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.copy_rounded, color: AppColors.lightBlue, size: 18),
        ),
      ),
    );
  }

  // ============================================================
  // INSTRUCTIONS
  // ============================================================

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tintColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'payment_instructions'.tr,
                  style: AppTheme.style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'payment_instructions_text'.tr,
                  style: AppTheme.style.copyWith(
                    fontSize: 11.5,
                    color: AppColors.hint,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/pay_emi_loading.json',
                  width: 320,
                  height: 320,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'loading_payment_details'.tr,
                  style: AppTheme.style.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'fetching_payment_information'.tr,
                    textAlign: TextAlign.center,
                    style: AppTheme.style.copyWith(
                      fontSize: 12,
                      color: AppColors.hint,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'unable_load_payment_details'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 12,
                color: AppColors.hint,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: Text(
                  'retry'.tr,
                  style: AppTheme.style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.tintColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.lightBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'payment_details_unavailable'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'payment_information_unavailable'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 12,
                color: AppColors.hint,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CLIPBOARD
  // ============================================================

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    Get.snackbar(
      'copied'.tr,
      value,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      backgroundColor: AppColors.lightBlue,
      colorText: AppColors.white,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
    );
  }
}
