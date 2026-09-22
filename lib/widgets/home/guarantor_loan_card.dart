import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/home_model.dart';
import '../../utils/app_colors.dart';

class GuarantorLoanCard extends StatelessWidget {
  const GuarantorLoanCard({super.key, required this.loan, required this.onTap});

  final HomeLoan loan;
  final VoidCallback onTap;

  String _currency(double value) {
    return value <= 0 ? '-' : '₹${value.toStringAsFixed(0)}';
  }

  String _value(String value) {
    return value.trim().isEmpty ? '-' : value;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = loan.loanSchemes.isEmpty ? null : loan.loanSchemes.first;
    final branch = loan.lead?.branch?.name ?? '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.84),
              AppColors.buttonEnd.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.buttonEnd.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.buttonEnd.withValues(alpha: 0.10),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.buttonEnd.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.buttonEnd,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'loan_number'.tr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _value(loan.loanNo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.lightBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              height: 1,
              color: AppColors.buttonEnd.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'loan_status'.tr,
                    value: loan.displayStatus,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'loan_amount'.tr,
                    value: _currency(loan.loanAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'emi_amount'.tr,
                    value: scheme == null ? '-' : _currency(scheme.emi),
                  ),
                ),
                Expanded(
                  child: _InfoItem(label: 'branch'.tr, value: _value(branch)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.lightBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
