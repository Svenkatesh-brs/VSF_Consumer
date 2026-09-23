import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/loan_details_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanDashboardProvider>();

    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: false,
        child: SafeArea(
          child: Obx(() {
            final borrower = controller.loanDetails.value?.borrower;
            final fallbackName = controller.dashboard.value?.borrowerName ?? '';
            final hasProfile = borrower != null || fallbackName.isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'back'.tr,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'my_profile'.tr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: controller.isLoading.value && !hasProfile
                      ? const Center(child: CircularProgressIndicator())
                      : hasProfile
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            _ProfileCard(
                              title: 'my_profile'.tr,
                              children: [
                                _ProfileField('name'.tr, borrower?.name ?? fallbackName),
                                _ProfileField('phone'.tr, borrower?.phone ?? ''),
                                _ProfileField('date_of_birth'.tr, borrower?.dob ?? ''),
                                _ProfileField('gender'.tr, borrower?.gender ?? ''),
                                _ProfileField('relation'.tr, borrower?.relation ?? ''),
                                _ProfileField('customer_id'.tr, borrower?.cifId ?? ''),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ProfileCard(
                              title: 'address'.tr,
                              children: [
                                _ProfileField('address'.tr, _formatAddress(borrower?.address)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ProfileCard(
                              title: 'bank_details'.tr,
                              children: [
                                _ProfileField('bank_name'.tr, borrower?.bankName ?? ''),
                                _ProfileField('account_number'.tr, _maskAccountNumber(borrower?.accountNumber ?? '')),
                                _ProfileField('ifsc_code'.tr, borrower?.ifscCode ?? ''),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            'no_data_found'.tr,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '--' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 3),
          Text(
            displayValue,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

String _formatAddress(LoanAddress? address) {
  if (address == null) return '';

  return <String>[
    address.houseNumber,
    address.floorNumber,
    address.addressLine1,
    address.addressLine2,
    address.streetName,
    address.apartmentName,
    address.buildingName,
    address.landmark,
    address.village,
    address.district,
    address.city,
    address.state,
    address.country,
    address.pincode,
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

String _maskAccountNumber(String accountNumber) {
  final value = accountNumber.trim();
  if (value.length <= 4) return value;

  return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
}
