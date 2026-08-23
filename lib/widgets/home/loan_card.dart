import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class HomeLoanCard extends StatelessWidget {
  const HomeLoanCard({
    super.key,
    required this.loanNumber,
    required this.borrowers,
    required this.amount,
    required this.status,
    this.onTap,
  });

  final String loanNumber;
  final List<String> borrowers;
  final double amount;
  final String status;
  final VoidCallback? onTap;

  bool get isInactive => status.toLowerCase() == 'inactive';

  Color get statusColor {
    return isInactive ? AppColors.primary : AppColors.buttonEnd;
  }

  IconData get statusIcon {
    return isInactive
        ? Icons.check_circle_outline
        : Icons.pending_actions_outlined;
  }

  String get formattedAmount {
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.82),
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
            // ------------------------------------------------------
            // TOP ROW
            // ------------------------------------------------------
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_outlined,
                    color: AppColors.lightBlue,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Loan Number',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loanNumber,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------
                // STATUS
                // --------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ------------------------------------------------------
            // DIVIDER
            // ------------------------------------------------------
            Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.06),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // BORROWER + AMOUNT
            // ------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.person_outline,
                    label: 'Borrowers',
                    value: borrowers.join(', '),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _InfoItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Loan Amount',
                    value: formattedAmount,
                    valueColor: AppColors.lightBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------------
            // VIEW DETAILS
            // ------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.buttonEnd,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: AppColors.buttonEnd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// INFORMATION ITEM
// ==================================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.secondary,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}