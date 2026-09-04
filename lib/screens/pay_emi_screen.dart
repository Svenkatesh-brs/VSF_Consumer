import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'dart:typed_data';

import '../providers/pay_emi_provider.dart';
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
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.lightBlue,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay EMI',
                  style: AppTheme.style.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
                Text(
                  'Make your EMI payment securely',
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
      onRefresh: controller.retry,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: 20),
            _buildQrCard(),
            const SizedBox(height: 22),
            _buildUpiSection(),
            const SizedBox(height: 22),
            _buildPaymentNumbersSection(),
            const SizedBox(height: 22),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.tintColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
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
                'Complete your EMI payment',
                style: AppTheme.style.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Use the QR code or any of the payment details below.',
                style: AppTheme.style.copyWith(
                  fontSize: 12.5,
                  color: AppColors.hint,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QR CARD
  // ============================================================

  Widget _buildQrCard() {
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
                      'Scan & Pay',
                      style: AppTheme.style.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan this QR using your preferred UPI app',
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
          _buildQrImage(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.tintColor.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Open Google Pay, PhonePe, Paytm or another UPI app and scan the QR code.',
                    style: AppTheme.style.copyWith(
                      fontSize: 11.5,
                      color: AppColors.hint,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrImage() {
    final images = controller.qrImages;

    if (images.isEmpty) {
      return _buildQrUnavailable();
    }

    if (images.length == 1) {
      return _buildSingleQrImage(images.first);
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: images.length,
            controller: PageController(viewportFraction: 0.88),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildSingleQrImage(images[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Swipe to view all ${images.length} QR codes',
          style: AppTheme.style.copyWith(fontSize: 11.5, color: AppColors.hint),
        ),
      ],
    );
  }

  Widget _buildSingleQrImage(Uint8List image) {
  return Container(
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
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        image,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return _buildQrUnavailable();
        },
      ),
    ),
  );
}

  Widget _buildQrUnavailable() {
    return Container(
      width: 230,
      height: 230,
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
            'QR code unavailable',
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
  // UPI SECTION
  // ============================================================

  Widget _buildUpiSection() {
    final upiIds = controller.upiIds;

    if (upiIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildPaymentDetailSection(
      title: 'Pay using UPI',
      subtitle: 'Copy a UPI ID and pay from your UPI app',
      icon: Icons.alternate_email_rounded,
      children: [
        ...upiIds.asMap().entries.map(
          (entry) => _buildCopyableItem(
            value: entry.value,
            label: 'UPI ID',
            icon: Icons.alternate_email_rounded,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT NUMBERS
  // ============================================================

  Widget _buildPaymentNumbersSection() {
    final numbers = controller.paymentNumbers;

    if (numbers.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildPaymentDetailSection(
      title: 'Payment Numbers',
      subtitle: 'Use any available payment number when required',
      icon: Icons.phone_android_rounded,
      children: [
        ...numbers.asMap().entries.map(
          (entry) => _buildCopyableItem(
            value: entry.value,
            label: 'Payment Number',
            icon: Icons.phone_android_rounded,
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
  // COPYABLE ITEM
  // ============================================================

  Widget _buildCopyableItem({
    required String value,
    required String label,
    required IconData icon,
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
          child: Icon(icon, color: AppColors.secondary, size: 19),
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
        _buildCopyButton(value),
      ],
    );
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
                  'Payment instructions',
                  style: AppTheme.style.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Complete your payment using the QR code, UPI ID or payment number provided above. Keep your payment confirmation for your records.',
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          const SizedBox(height: 45),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.tintColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading payment details',
            style: AppTheme.style.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait while we fetch the latest payment information.',
            textAlign: TextAlign.center,
            style: AppTheme.style.copyWith(
              fontSize: 12,
              color: AppColors.hint,
              height: 1.4,
            ),
          ),
        ],
      ),
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
              'Unable to load payment details',
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
                  'Retry',
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
              'Payment details unavailable',
              textAlign: TextAlign.center,
              style: AppTheme.style.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Payment information is currently unavailable. Please try again later.',
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
      'Copied',
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
