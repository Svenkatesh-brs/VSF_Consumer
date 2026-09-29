import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';

// ============================================================
// LOAN PICKER DIALOG
//
// Compact modal used by the Profile Drawer's Quick Actions to pick
// the loan every loan-specific action will act on.
//
//   * Reads the ALREADY LOADED "My Loans" data (HomeProvider.loans)
//     — it never fires an API request of its own and never invents
//     a new endpoint.
//   * Shows the complete loan number of every option.
//   * Scrolls when the customer owns many loans.
//   * Closes right after a selection and returns the chosen
//     "My Loans" card map so the caller can hand it to
//     LoanDashboardProvider.selectLoan.
//   * Handles the empty and still-loading lists gracefully.
//   * Follows the active theme (dialog surface and unselected
//     indicator come from ThemeData), so it stays readable in
//     light and dark mode.
// ============================================================

class LoanPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> loans;

  final String selectedLoanNumber;

  final bool isLoading;

  const LoanPickerDialog({
    super.key,
    required this.loans,
    required this.selectedLoanNumber,
    this.isLoading = false,
  });

  // ============================================================
  // SHOW
  // ============================================================

  /// Presents the picker and resolves to the chosen "My Loans" card
  /// map, or null when the customer dismissed the dialog.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> loans,
    required String selectedLoanNumber,
    bool isLoading = false,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => LoanPickerDialog(
        loans: loans,
        selectedLoanNumber: selectedLoanNumber,
        isLoading: isLoading,
      ),
    );
  }

  // ============================================================
  // LOAN NUMBER
  // ============================================================

  static String loanNumberOf(Map<String, dynamic> loan) {
    return loan['loanNumber']?.toString().trim() ?? '';
  }

  static List<String> borrowersOf(Map<String, dynamic> loan) {
    final borrowers = loan['borrowers'];

    if (borrowers is! List) {
      return const <String>[];
    }

    return borrowers
        .map((borrower) => borrower?.toString().trim() ?? '')
        .where((borrower) => borrower.isNotEmpty)
        .toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text('select_loan'.tr),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: ConstrainedBox(
        // Keeps the dialog compact on phones and scrollable for
        // customers who own many loans.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: _buildBody(context, theme),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'cancel'.tr,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (loans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'loading'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 40,
                    color: AppColors.lightBlue.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'no_loans_available'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'loan_information_placeholder'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: loans
            .map(
              (loan) => _buildLoanTile(
                context,
                theme,
                loan,
                loanNumberOf(loan) == selectedLoanNumber,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLoanTile(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> loan,
    bool isSelected,
  ) {
    final loanNumber = loanNumberOf(loan);

    final borrowers = borrowersOf(loan).join(', ');

    final amount = loan['amount'];

    final amountText = amount is num ? '₹${amount.toDouble().toStringAsFixed(0)}' : '';

    final subtitleParts = <String>[
      if (borrowers.isNotEmpty) borrowers,
      if (amountText.isNotEmpty) amountText,
      if ((loan['status']?.toString() ?? '').isNotEmpty)
        loan['status'].toString(),
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? AppColors.buttonEnd : theme.colorScheme.outline,
      ),
      title: Text(
        loanNumber.isEmpty ? '-' : loanNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.lightBlue : null,
        ),
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: () => Navigator.of(context).pop(loan),
    );
  }
}
