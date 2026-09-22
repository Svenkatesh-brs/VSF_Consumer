import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/home_model.dart';
import '../../utils/app_colors.dart';

class GuarantorLoanDetailsDialog extends StatelessWidget {
  const GuarantorLoanDetailsDialog({super.key, required this.loan});

  final HomeLoan loan;

  static Future<void> show(BuildContext context, HomeLoan loan) {
    return showDialog<void>(
      context: context,
      builder: (_) => GuarantorLoanDetailsDialog(loan: loan),
    );
  }

  String _currency(double value) {
    return value <= 0 ? '' : '₹${value.toStringAsFixed(0)}';
  }

  String _date(dynamic value) {
    if (value is int && value > 0) {
      final milliseconds = value < 100000000000 ? value * 1000 : value;
      final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return text;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _text(String value) => value.trim();

  @override
  Widget build(BuildContext context) {
    final scheme = loan.loanSchemes.isEmpty ? null : loan.loanSchemes.first;
    final lead = loan.lead;
    final payment = loan.payment;
    final borrowerNames =
        lead?.borrowers
            .map((borrower) => borrower.name)
            .where((name) => name.isNotEmpty)
            .join(', ') ??
        '';
    final guarantorCount = lead?.guarantors.length ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'guarantor_loan_details'.tr,
                      style: const TextStyle(
                        color: AppColors.lightBlue,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'close'.tr,
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('loan_information'.tr, [
                      _row('loan_number'.tr, _text(loan.loanNo)),
                      _row('loan_status'.tr, loan.displayStatus),
                      _row(
                        'loan_stage'.tr,
                        loan.loanStage <= 0 ? '' : '${loan.loanStage}',
                      ),
                      _row(
                        'principal_amount'.tr,
                        _currency(loan.principalAmount),
                      ),
                      _row('loan_amount'.tr, _currency(loan.loanAmount)),
                      _row(
                        'emi_amount'.tr,
                        scheme == null ? '' : _currency(scheme.emi),
                      ),
                      _row(
                        'installments'.tr,
                        scheme == null || scheme.noOfInstallments <= 0
                            ? ''
                            : '${scheme.noOfInstallments}',
                      ),
                      _row(
                        'tenure'.tr,
                        lead == null || lead.tenure <= 0
                            ? ''
                            : '${lead.tenure}',
                      ),
                      _row('interest_type'.tr, _text(loan.interestType)),
                      _row(
                        'interest_rate'.tr,
                        loan.interest <= 0
                            ? ''
                            : '${loan.interest.toStringAsFixed(2)}%',
                      ),
                      _row(
                        'irr'.tr,
                        loan.irr <= 0 ? '' : '${loan.irr.toStringAsFixed(2)}%',
                      ),
                      _row('file_number'.tr, _text(payment?.fileNumber ?? '')),
                    ]),
                    _section('important_dates'.tr, [
                      _row(
                        'loan_creation_date'.tr,
                        _date(payment?.loanCreationDate),
                      ),
                      _row('emi_start_date'.tr, _date(payment?.emiStartDate)),
                      _row('agreement_date'.tr, _date(loan.agreementDate)),
                      _row('installment_date'.tr, _date(loan.installmentDate)),
                      _row('created'.tr, _date(loan.createdAt)),
                    ]),
                    _section('loan_context'.tr, [
                      _row('branch'.tr, _text(lead?.branch?.name ?? '')),
                      _row('loan_type'.tr, _text(lead?.loanType?.name ?? '')),
                      // _row('loan_scheme'.tr, _text(lead?.loanScheme ?? '')),
                      // _row('product'.tr, _text(lead?.productType ?? '')),
                      _row('borrowers'.tr, borrowerNames),
                      _row(
                        'guarantors'.tr,
                        guarantorCount <= 0 ? '' : '$guarantorCount',
                      ),
                    ]),
                    _section('payment_summary'.tr, [
                      _row('total_emi_paid'.tr, _currency(loan.totalEMIPaid)),
                      // _row(
                      //   'total_lpc_received'.tr,
                      //   _currency(loan.totalLpcReceived),
                      // ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    final visibleRows = rows.where((row) => row is! SizedBox).toList();
    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.lightBlue,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.lightBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
