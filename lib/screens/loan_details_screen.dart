import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../providers/loan_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';

class LoanDetailsScreen extends GetView<LoanProvider> {
  const LoanDetailsScreen({super.key});

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.lightBlue),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard({
    required String title,
    required IconData icon,
    required String name,
    required String subtitle,
    required String phone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: AppColors.lightBlue),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.lightBlue,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 17, color: Colors.black45),
              const SizedBox(width: 8),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: false,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Obx(() {
              if (controller.selectedLoan.value == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------
                  Row(
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
                          onPressed: Get.back,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 21,
                            color: AppColors.lightBlue,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan Details',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lightBlue,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'View your loan information',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.75),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/vsf.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ------------------------------------------------
                  // STATUS HERO CARD
                  // ------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.38),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withValues(alpha: 0.10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 28,
                            color: AppColors.secondary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Loan Status',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: controller.status == 'Completed'
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.buttonEnd.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            controller.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: controller.status == 'Completed'
                                  ? AppColors.primary
                                  : AppColors.buttonEnd,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          controller.vehicleNumber,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.lightBlue,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 5),

                        Text(
                          controller.borrowerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // LOAN INFORMATION CARD
                  // ------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loan Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightBlue,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildDetailRow(
                          icon: Icons.currency_rupee_rounded,
                          label: 'Loan Amount',
                          value: '₹${controller.amount.toStringAsFixed(0)}',
                        ),

                        const SizedBox(height: 14),

                        _buildDetailRow(
                          icon: Icons.directions_car_outlined,
                          label: 'Vehicle Number',
                          value: controller.vehicleNumber,
                        ),

                        const SizedBox(height: 14),

                        _buildDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Borrower',
                          value: controller.borrowerName,
                        ),

                        const SizedBox(height: 14),

                        _buildDetailRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Status',
                          value: controller.status,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // BORROWER DETAILS
                  // ------------------------------------------------
                  _buildPersonCard(
                    title: 'Borrower Details',
                    icon: Icons.person_rounded,
                    name: controller.borrowerName,
                    subtitle: 'Primary Borrower',
                    phone: '+91 98765 43210',
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // GUARANTOR DETAILS
                  // ------------------------------------------------
                  _buildPersonCard(
                    title: 'Guarantor Details',
                    icon: Icons.verified_user_outlined,
                    name: controller.guarantorName,
                    subtitle: controller.guarantorRelation,
                    phone: controller.guarantorMobile,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
