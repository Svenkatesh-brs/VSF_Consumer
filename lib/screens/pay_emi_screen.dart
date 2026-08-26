import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';
import '../utils/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/common/app_card.dart';

class PayEmiScreen extends StatefulWidget {
  const PayEmiScreen({super.key});

  @override
  State<PayEmiScreen> createState() => _PayEmiScreenState();
}

class _PayEmiScreenState extends State<PayEmiScreen> {
  String _selectedPaymentMethod = 'UPI';

  final List<_PaymentMethod> _paymentMethods = const [
    _PaymentMethod(
      title: 'UPI',
      subtitle: 'Google Pay, PhonePe and other UPI apps',
      icon: Icons.account_balance_wallet_rounded,
    ),
    _PaymentMethod(
      title: 'Debit / Credit Card',
      subtitle: 'Visa, Mastercard and supported cards',
      icon: Icons.credit_card_rounded,
    ),
    _PaymentMethod(
      title: 'Net Banking',
      subtitle: 'Pay directly through your bank',
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 20),
                      _buildLoanSummary(),
                      const SizedBox(height: 16),
                      _buildPaymentAmount(),
                      const SizedBox(height: 22),
                      _buildPaymentMethods(),
                      const SizedBox(height: 22),
                      _buildSecurityNote(),
                      const SizedBox(height: 28),
                      _buildProceedButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          Text(
            'Pay EMI',
            style: AppTheme.style.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Text(
      'Complete your EMI payment securely and conveniently.',
      style: AppTheme.style.copyWith(
        fontSize: 14,
        color: AppColors.hint,
        height: 1.5,
      ),
    );
  }

  Widget _buildLoanSummary() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.tintColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.lightBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loan Payment',
                style: AppTheme.style.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SummaryRow(
            label: 'Loan No.',
            value: 'VSF-XXXXXXXX',
          ),
          const SizedBox(height: 13),
          const _SummaryRow(
            label: 'EMI Due Date',
            value: 'DD MMM YYYY',
          ),
          const SizedBox(height: 13),
          const _SummaryRow(
            label: 'Payment Status',
            value: 'Due',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmount() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Amount',
            style: AppTheme.style.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.lightBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amount payable for the current EMI',
            style: AppTheme.style.copyWith(
              fontSize: 13,
              color: AppColors.hint,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: AppColors.tintColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '9,020',
                  style: AppTheme.style.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightBlue,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: AppTheme.style.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how you want to pay',
          style: AppTheme.style.copyWith(
            fontSize: 13,
            color: AppColors.hint,
          ),
        ),
        const SizedBox(height: 14),
        ..._paymentMethods.map(_buildPaymentMethodCard),
      ],
    );
  }

  Widget _buildPaymentMethodCard(_PaymentMethod method) {
    final selected = _selectedPaymentMethod == method.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method.title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.tintColor.withValues(alpha: 0.55)
                : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.inputBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightBlack.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.tintColor
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  method.icon,
                  color: selected
                      ? AppColors.lightBlue
                      : AppColors.hint,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: AppTheme.style.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      method.subtitle,
                      style: AppTheme.style.copyWith(
                        fontSize: 11.5,
                        color: AppColors.hint,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.hint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.tintColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.lightBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment will be processed through a secure payment gateway.',
              style: AppTheme.style.copyWith(
                fontSize: 12,
                color: AppColors.hint,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.buttonStart,
              AppColors.buttonEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.buttonShadow,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Get.snackbar(
              'Payment',
              'Payment gateway integration will be available soon.',
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.lock_rounded),
          label: Text(
            'Proceed to Pay',
            style: AppTheme.style.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.style.copyWith(
              fontSize: 13,
              color: AppColors.hint,
            ),
          ),
        ),
        Text(
          value,
          style: AppTheme.style.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethod {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentMethod({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}