import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/common/app_loading.dart';
import '../models/transactions_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final LoanDashboardProvider controller;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // Reuses the live provider (and its already-fetched
    // TransactionsModel) from the Loan Dashboard route.
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

    await Future.delayed(const Duration(milliseconds: 400));

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

  // ============================================================
  // TYPE BADGE
  //
  // Derived from the merged voucher components: 'EMI Receipt',
  // 'VAS Receipt', 'Mixed Receipt' or 'Charges Receipt'.
  // ============================================================

  Widget _buildTypeBadge(String type) {
    final isEmi = type.toLowerCase().contains('emi');

    final badgeColor = isEmi ? AppColors.buttonEnd : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeColor.withValues(alpha: 0.16)),
      ),
      child: Text(
        type.isEmpty ? '-' : type,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: badgeColor,
        ),
      ),
    );
  }

  // ============================================================
  // COMPONENT PILL
  //
  // Shows one collected component (EMI / VAS / LPC /
  // Collection / Seize) of the merged voucher receipt.
  // ============================================================

  // Widget _buildComponentPill(String label, double amount) {
  //   return Flexible(
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  //       decoration: BoxDecoration(
  //         color: Colors.black.withValues(alpha: 0.04),
  //         borderRadius: BorderRadius.circular(100),
  //       ),
  //       child: Text(
  //         '$label ${_formatAmount(amount)}',
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //         style: const TextStyle(
  //           fontSize: 9,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.black54,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ============================================================
  // TRANSACTION CARD
  // ============================================================

  Widget _buildTransactionCard(LoanTransaction transaction) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.receiptPreview, arguments: transaction),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.80),
              Colors.white.withValues(alpha: 0.48),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------
            // TOP ROW: DESCRIPTION + AMOUNT
            // ------------------------------------------------------

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    size: 19,
                    color: AppColors.lightBlue,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description.isEmpty
                            ? '-'
                            : transaction.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Voucher '
                        '${transaction.voucherNo.isEmpty ? '-' : transaction.voucherNo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(transaction.amountCollected),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightBlue,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      controller.formatDateMs(transaction.dateMs),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ------------------------------------------------------
            // BOTTOM ROW: TYPE + COLLECTED COMPONENTS
            //
            // Every component actually collected on this voucher
            // appears as its own pill; the headline amount above is
            // amountCollected (sum of all components).
            // ------------------------------------------------------
            if (transaction.type.isNotEmpty || transaction.hasExtras)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _buildTypeBadge(transaction.type),

                    // if (transaction.emiAmount > 0) ...[
                    //   const SizedBox(width: 6),
                    //   _buildComponentPill('EMI', transaction.emiAmount),
                    // ],

                    // if (transaction.vasAmount > 0) ...[
                    //   const SizedBox(width: 6),
                    //   _buildComponentPill('VAS', transaction.vasAmount),
                    // ],

                    // if (transaction.lpcAmount > 0) ...[
                    //   const SizedBox(width: 6),
                    //   _buildComponentPill('LPC', transaction.lpcAmount),
                    // ],

                    // if (transaction.collectionCharge > 0) ...[
                    //   const SizedBox(width: 6),
                    //   _buildComponentPill(
                    //     'Collection',
                    //     transaction.collectionCharge,
                    //   ),
                    // ],

                    // if (transaction.seizeCharge > 0) ...[
                    //   const SizedBox(width: 6),
                    //   _buildComponentPill('Seize', transaction.seizeCharge),
                    // ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 42,
              color: AppColors.lightBlue.withValues(alpha: 0.45),
            ),

            const SizedBox(height: 14),

            const Text(
              'No transactions found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR / RETRY VIEW
  //
  // Shown when the shared provider has no transactions yet and
  // its load attempt failed. Uses the existing retry flow.
  // ============================================================

  Widget _buildErrorView() {
    final errorMessage = controller.errorMessage.value ?? '';

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
                borderRadius: BorderRadius.circular(100),
                onTap: controller.retry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.buttonStart, AppColors.buttonEnd],
                    ),
                    borderRadius: BorderRadius.circular(100),
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

  Widget _buildContent(List<LoanTransaction> transactions) {
    return RefreshIndicator(
      onRefresh: controller.retry,
      color: AppColors.lightBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ENTRY LEFT - 0ms
          // EXIT RIGHT - 0ms
          // ==================================================

          ScreenContentExit(
            isExiting: _isExiting,
            direction: ContentExitDirection.toRight,
            delay: Duration.zero,
            child: ScreenContentTransition(
              direction: ContentTransitionDirection.fromLeft,
              delay: Duration.zero,
              child: Row(
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
                      onPressed: _goBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 21,
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightBlue,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          transactions.isEmpty
                              ? 'Payment history'
                              : '${transactions.length} '
                                    '${transactions.length == 1 ? 'record' : 'records'}',
                          style: const TextStyle(
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
          ),

          const SizedBox(height: 24),

          // ==================================================
          // TRANSACTION LIST
          // ENTRY LEFT - 80ms
          // EXIT RIGHT - 80ms
          // ==================================================
          if (transactions.isEmpty)
            ScreenContentExit(
              isExiting: _isExiting,
              direction: ContentExitDirection.toRight,
              delay: const Duration(milliseconds: 80),
              child: ScreenContentTransition(
                direction: ContentTransitionDirection.fromLeft,
                delay: const Duration(milliseconds: 80),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: double.infinity,
                  child: _buildEmptyState(),
                ),
              ),
            )
          else
            ScreenContentExit(
              isExiting: _isExiting,
              direction: ContentExitDirection.toRight,
              delay: const Duration(milliseconds: 80),
              child: ScreenContentTransition(
                direction: ContentTransitionDirection.fromLeft,
                delay: const Duration(milliseconds: 80),
                child: Column(
                  children: transactions.map(_buildTransactionCard).toList(),
                ),
              ),
            ),
        ],
      ),
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
            final model = controller.transactions.value;

            final transactions =
                model?.transactions ?? const <LoanTransaction>[];

            if (model == null) {
              final isLoading = controller.isLoading.value;

              if (!isLoading && controller.errorMessage.value != null) {
                return _buildErrorView();
              }

              return const AppLoading(
                message: 'Loading transactions',
                subtitle: 'Please wait while we fetch your payment history.',
                size: 300,
              );
            }

            return _buildContent(transactions);
          }),
        ),
      ),
    );
  }
}
