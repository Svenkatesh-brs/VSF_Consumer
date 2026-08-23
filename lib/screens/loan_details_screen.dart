import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/loan_details_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

class LoanDetailsScreen extends StatefulWidget {
  const LoanDetailsScreen({super.key});

  @override
  State<LoanDetailsScreen> createState() =>
      _LoanDetailsScreenState();
}

class _LoanDetailsScreenState
    extends State<LoanDetailsScreen> {
  late final LoanDashboardProvider controller;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // Reuses the live provider (and its already-fetched
    // LoanDetailsModel) from the Loan Dashboard route.
    // No additional API call is made here.
    // ----------------------------------------------------------

    controller = Get.find<LoanDashboardProvider>();
  }

  // ============================================================
  // BACK NAVIGATION
  // ============================================================

  Future<void> _goBack() async {
    if (_isExiting) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isExiting = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    Get.back();
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatPercent(double value) {
    return '${value.toStringAsFixed(2)}%';
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.80),
            Colors.white.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.lightBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  //
  // Empty or missing values render as a dash; never throws on
  // null data from the API.
  // ============================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    final displayValue =
        value.trim().isEmpty ? '-' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 1,
        color: AppColors.lightBlue
            .withValues(alpha: 0.07),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final isActive =
        status.toLowerCase() == 'active';

    final statusColor = isActive
        ? AppColors.buttonStart
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMATED SECTION WRAPPER
  // ============================================================

  Widget _wrapAnimated({
    required int delayMs,
    required Widget child,
  }) {
    return ScreenContentExit(
      isExiting: _isExiting,
      direction: ContentExitDirection.toRight,
      delay: Duration(milliseconds: delayMs),
      child: ScreenContentTransition(
        direction: ContentTransitionDirection.fromLeft,
        delay: Duration(milliseconds: delayMs),
        child: child,
      ),
    );
  }

  // ============================================================
  // BUILD LOAN SUMMARY SECTION
  // ============================================================

  Widget _buildLoanSummarySection(
    LoanDetailsModel details,
  ) {
    return _buildSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Loan Summary',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOAN NUMBER',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    details.loanNo.isEmpty
                        ? '-'
                        : details.loanNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(details.displayStatus),
          ],
        ),

        const SizedBox(height: 14),

        _buildInfoRow(
          label: 'Branch',
          value: details.branchName,
        ),
        _buildInfoRow(
          label: 'Product',
          value: details.productName,
        ),
        _buildInfoRow(
          label: 'Loan Type',
          value: details.loanTypeName,
        ),
        _buildInfoRow(
          label: 'Loan Scheme',
          value: details.schemeName,
        ),
      ],
    );
  }

  // ============================================================
  // BUILD FINANCIAL SECTION
  // ============================================================

  Widget _buildFinancialSection(
    LoanDetailsModel details,
  ) {
    return _buildSectionCard(
      icon: Icons.currency_rupee_rounded,
      title: 'Financial Details',
      children: [
        _buildInfoRow(
          label: 'Principal Amount',
          value:
              _formatAmount(details.principalAmount),
        ),
        _buildInfoRow(
          label: 'Interest Rate',
          value:
              _formatPercent(details.interestRate),
        ),
        _buildInfoRow(
          label: 'IRR',
          value: _formatPercent(details.irr),
        ),
        _buildInfoRow(
          label: 'EMI Amount',
          value: _formatAmount(details.emiAmount),
        ),
        _buildInfoRow(
          label: 'Number of Installments',
          value: details.numberOfInstallments <= 0
              ? '-'
              : details.numberOfInstallments
                  .toString(),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD DATES SECTION
  // ============================================================

  Widget _buildDatesSection(
    LoanDetailsModel details,
  ) {
    return _buildSectionCard(
      icon: Icons.calendar_today_outlined,
      title: 'Important Dates',
      children: [
        _buildInfoRow(
          label: 'Agreement Date',
          value: controller
              .formatDateMs(details.agreementDateMs),
        ),
        _buildInfoRow(
          label: 'EMI Start Date',
          value: controller
              .formatDateMs(details.emiStartDateMs),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD BORROWER SECTION
  // ============================================================

  Widget _buildBorrowerSection(
    LoanDetailsModel details,
  ) {
    final borrower = details.borrower;

    final addressParts = <String>[
      if (borrower != null &&
          borrower.addressLine1.isNotEmpty)
        borrower.addressLine1,
      if (borrower != null && borrower.city.isNotEmpty)
        borrower.city,
      if (borrower != null && borrower.state.isNotEmpty)
        borrower.state,
      if (borrower != null &&
          borrower.pincode.isNotEmpty)
        borrower.pincode,
    ];

    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Borrower',
      children: [
        _buildInfoRow(
          label: 'Name',
          value: borrower?.name ?? '',
        ),
        _buildInfoRow(
          label: 'CIF ID',
          value: borrower?.cifId ?? '',
        ),
        _buildInfoRow(
          label: 'Phone',
          value: borrower?.phone ?? '',
        ),
        _buildInfoRow(
          label: 'Date of Birth',
          value: borrower?.dob ?? '',
        ),
        _buildInfoRow(
          label: 'Gender',
          value: borrower?.gender ?? '',
        ),
        _buildInfoRow(
          label: 'Relation',
          value: borrower?.relation ?? '',
        ),
        _buildInfoRow(
          label: 'Address',
          value: addressParts.join(', '),
        ),
        _buildDivider(),
        _buildInfoRow(
          label: 'Bank Name',
          value: borrower?.bankName ?? '',
        ),
        _buildInfoRow(
          label: 'Account Number',
          value: borrower?.accountNumber ?? '',
        ),
        _buildInfoRow(
          label: 'IFSC Code',
          value: borrower?.ifscCode ?? '',
        ),
      ],
    );
  }

  // ============================================================
  // BUILD GUARANTORS SECTION
  // ============================================================

  Widget _buildGuarantorsSection(
    LoanDetailsModel details,
  ) {
    final guarantors = details.guarantors;

    final children = <Widget>[];

    if (guarantors.isEmpty) {
      children.add(
        const Text(
          'No guarantor information available.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
        ),
      );
    } else {
      for (var index = 0;
          index < guarantors.length;
          index++) {
        final guarantor = guarantors[index];

        if (index > 0) {
          children.add(_buildDivider());
        }

        children.addAll([
          _buildInfoRow(
            label: 'Name',
            value: guarantor.name,
          ),
          _buildInfoRow(
            label: 'Relation',
            value: guarantor.relation,
          ),
          _buildInfoRow(
            label: 'Phone',
            value: guarantor.phone,
          ),
        ]);
      }
    }

    return _buildSectionCard(
      icon: Icons.people_outline_rounded,
      title: 'Guarantors',
      children: children,
    );
  }

  // ============================================================
  // BUILD VEHICLE SECTION
  // ============================================================

  Widget _buildVehicleSection(
    LoanDetailsModel details,
  ) {
    final asset = details.asset;

    return _buildSectionCard(
      icon: Icons.two_wheeler_outlined,
      title: 'Vehicle Details',
      children: [
        _buildInfoRow(
          label: 'Registration Number',
          value: asset?.registrationNumber ?? '',
        ),
        _buildInfoRow(
          label: 'Make',
          value: asset?.makeName ?? '',
        ),
        _buildInfoRow(
          label: 'Model',
          value: asset?.modelName ?? '',
        ),
        _buildInfoRow(
          label: 'Vehicle Type',
          value: asset?.vehicleType ?? '',
        ),
        _buildInfoRow(
          label: 'Fuel Type',
          value: asset?.fuelType ?? '',
        ),
        _buildInfoRow(
          label: 'Manufacture Year',
          value: asset?.manufactureYear ?? '',
        ),
        _buildInfoRow(
          label: 'Engine Number',
          value: asset?.engineNumber ?? '',
        ),
        _buildInfoRow(
          label: 'Chassis Number',
          value: asset?.chassisNumber ?? '',
        ),
        _buildInfoRow(
          label: 'Owner Name',
          value: asset?.ownerName ?? '',
        ),
        _buildInfoRow(
          label: 'Invoice Amount',
          value: asset == null
              ? ''
              : _formatAmount(asset.invoiceAmount),
        ),
        _buildInfoRow(
          label: 'On-Road Price',
          value: asset == null
              ? ''
              : _formatAmount(asset.onRoadPrice),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD DISBURSEMENT SECTION
  // ============================================================

  Widget _buildDisbursementSection(
    LoanDetailsModel details,
  ) {
    final disbursement =
        details.disbursementSummary;

    return _buildSectionCard(
      icon: Icons.payments_outlined,
      title: 'Disbursement',
      children: [
        _buildInfoRow(
          label: 'Total Loan Amount',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.totalLoanAmount,
                ),
        ),
        _buildInfoRow(
          label: 'Adjustments',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.adjustmentsAmount,
                ),
        ),
        _buildInfoRow(
          label: 'Advance EMI',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.advanceEmiAmount,
                ),
        ),
        _buildInfoRow(
          label: 'Deduction',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.deductionAmount,
                ),
        ),
        _buildInfoRow(
          label: 'Charges',
          value: disbursement == null
              ? ''
              : _formatAmount(disbursement.chargeAmount),
        ),
        _buildInfoRow(
          label: 'Down Payment',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.downPaymentAmount,
                ),
        ),
        _buildInfoRow(
          label: 'Amount to be Paid',
          value: disbursement == null
              ? ''
              : _formatAmount(
                  disbursement.amountToBePaid,
                ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR / RETRY VIEW
  //
  // Shown when the shared provider has no loan details yet and
  // its load attempt failed. Uses the existing retry flow.
  // ============================================================

  Widget _buildErrorView() {
    final errorMessage =
        controller.errorMessage.value ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.lightBlue,
            ),

            const SizedBox(height: 14),

            Text(
              errorMessage.isEmpty
                  ? 'Unable to load your loan information.'
                  : errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 18),

            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(100),
                onTap: controller.retry,
                child: Container(
                  padding: const EdgeInsets
                      .symmetric(
                    horizontal: 26,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.buttonStart,
                        AppColors.buttonEnd,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
  // BUILD CONTENT
  // ============================================================

  Widget _buildContent(LoanDetailsModel details) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          _wrapAnimated(
            delayMs: 0,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _goBack,
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                        'Complete loan information',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // SECTIONS
          // ==================================================

          _wrapAnimated(
            delayMs: 80,
            child: _buildLoanSummarySection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 160,
            child: _buildFinancialSection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 240,
            child: _buildDatesSection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 320,
            child: _buildBorrowerSection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 400,
            child: _buildGuarantorsSection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 480,
            child: _buildVehicleSection(details),
          ),

          const SizedBox(height: 16),

          _wrapAnimated(
            delayMs: 560,
            child: _buildDisbursementSection(details),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: false,
        child: SafeArea(
          child: Obx(() {
            final details =
                controller.loanDetails.value;

            if (details == null) {
              final isLoading =
                  controller.isLoading.value;

              if (!isLoading &&
                  controller.errorMessage.value !=
                      null) {
                return _buildErrorView();
              }

              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            return _buildContent(details);
          }),
        ),
      ),
    );
  }
}
