import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/home_model.dart';
import '../../utils/app_colors.dart';

class GuarantorLoanDetailsDialog extends StatefulWidget {
  const GuarantorLoanDetailsDialog({super.key, required this.loan});

  final HomeLoan loan;

  static Future<void> show(BuildContext context, HomeLoan loan) {
    return showDialog<void>(
      context: context,
      builder: (_) => GuarantorLoanDetailsDialog(loan: loan),
    );
  }

  @override
  State<GuarantorLoanDetailsDialog> createState() =>
      _GuarantorLoanDetailsDialogState();
}

class _GuarantorLoanDetailsDialogState extends State<GuarantorLoanDetailsDialog>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // OVERDUE PULSE
  //
  // Subtle red pulse shown at the top of the dialog while an
  // overdue count exists. Mirrors the existing overdue animation
  // conventions used in the loan overview card.
  // ============================================================

  late final AnimationController _overdueController;

  int get _overdueCount => widget.loan.overDueEMICount;

  @override
  void initState() {
    super.initState();

    _overdueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (_overdueCount > 0) {
      _overdueController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _overdueController.dispose();
    super.dispose();
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

  // ============================================================
  // OVERDUE BANNER
  // ============================================================

  Widget _buildOverdueBanner() {
    return AnimatedBuilder(
      animation: _overdueController,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_overdueController.value);

        final borderAlpha = 0.16 + (t * 0.26);

        final glowAlpha = 0.10 + (t * 0.16);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: borderAlpha),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: glowAlpha),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              _OverduePulseDot(animation: _overdueController),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (_overdueCount == 1 ? 'emi_overdue' : 'emis_overdue')
                      .trParams({'count': '$_overdueCount'}),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.loan.loanSchemes.isEmpty
        ? null
        : widget.loan.loanSchemes.first;
    final lead = widget.loan.lead;
    final payment = widget.loan.payment;
    final borrowerNames =
        lead?.borrowers
            .map((borrower) => borrower.name)
            .where((name) => name.isNotEmpty)
            .join(', ') ??
        '';
    final guarantorCount = lead?.guarantors.length ?? 0;

    final guarantorNames =
        lead?.guarantors
            .map((guarantor) => guarantor.name)
            .where((name) => name.isNotEmpty)
            .join(', ') ??
        '';

    final guarantorRelations =
        lead?.guarantors
            .map((guarantor) => guarantor.relation)
            .where((relation) => relation.isNotEmpty)
            .join(', ') ??
        '';

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

            if (widget.loan.overDueEMICount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _buildOverdueBanner(),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('loan_information'.tr, [
                      _row('loan_number'.tr, _text(widget.loan.loanNo)),
                      _row('loan_status'.tr, widget.loan.displayStatus),
                      _row(
                        'loan_stage'.tr,
                        widget.loan.loanStage <= 0
                            ? ''
                            : '${widget.loan.loanStage}',
                      ),
                      _row(
                        'principal_amount'.tr,
                        _currency(widget.loan.principalAmount),
                      ),
                      _row('loan_amount'.tr, _currency(widget.loan.loanAmount)),
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
                      // _row('interest_type'.tr, _text(widget.loan.interestType)),
                      _row(
                        'interest_rate'.tr,
                        widget.loan.interest <= 0
                            ? ''
                            : '${widget.loan.interest.toStringAsFixed(2)}%',
                      ),
                      _row(
                        'irr'.tr,
                        widget.loan.irr <= 0
                            ? ''
                            : '${widget.loan.irr.toStringAsFixed(2)}%',
                      ),
                      _row('file_number'.tr, _text(payment?.fileNumber ?? '')),
                    ]),
                    _section('important_dates'.tr, [
                      _row(
                        'loan_creation_date'.tr,
                        _date(payment?.loanCreationDate),
                      ),
                      _row('emi_start_date'.tr, _date(payment?.emiStartDate)),
                      _row(
                        'agreement_date'.tr,
                        _date(widget.loan.agreementDate),
                      ),
                      _row(
                        'installment_date'.tr,
                        _date(widget.loan.installmentDate),
                      ),
                      _row('created'.tr, _date(widget.loan.createdAt)),
                    ]),
                    _section('loan_context'.tr, [
                      _row('branch'.tr, _text(lead?.branch?.name ?? '')),
                      _row('loan_type'.tr, _text(lead?.loanType?.name ?? '')),
                      // _row('loan_scheme'.tr, _text(lead?.loanScheme ?? '')),
                      // _row('product'.tr, _text(lead?.productType ?? '')),
                      _row('borrowers'.tr, borrowerNames),
                      _row('guarantor'.tr, guarantorNames),
                      _row(
                        'guarantor_relation'.tr,
                        guarantorRelations.isNotEmpty
                            ? guarantorRelations
                            : guarantorCount <= 0
                            ? ''
                            : '$guarantorCount',
                      ),
                    ]),
                    _section('payment_summary'.tr, [
                      if (widget.loan.totalEMICount > 0) ...[
                        _row('total_emis'.tr, '${widget.loan.totalEMICount}'),
                        _row('paid_emis'.tr, '${widget.loan.paidEMICount}'),
                        _row(
                          'upcoming_emis'.tr,
                          '${widget.loan.upcomingEMICount}',
                        ),
                        _row(
                          'overdue_emis'.tr,
                          '${widget.loan.overDueEMICount}',
                          valueColor: widget.loan.overDueEMICount > 0
                              ? AppColors.error
                              : null,
                        ),
                      ],
                      _row(
                        'total_emi_paid'.tr,
                        _currency(widget.loan.totalEMIPaid),
                      ),
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

  Widget _row(String label, String value, {Color? valueColor}) {
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
              style: TextStyle(
                color: valueColor ?? AppColors.lightBlue,
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

// ================================================================
// OVERDUE PULSE DOT
//
// Small pulsing red dot that slowly draws the eye to the overdue
// banner. Mirrors the pulsing status dot convention already used
// by the loan overview card.
// ================================================================

class _OverduePulseDot extends StatelessWidget {
  const _OverduePulseDot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 0.80 + (animation.value * 0.30);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(
                    alpha: 0.25 + (animation.value * 0.35),
                  ),
                  blurRadius: 7,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
