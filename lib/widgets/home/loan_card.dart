import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                      Text(
                        'loan_number'.tr,
                        style: const TextStyle(
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
                    label: 'borrowers'.tr,
                    value: borrowers.join(', '),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: _InfoItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'loan_amount'.tr,
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
            HomeLoanDetailsButton(onTap: onTap),
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

class HomeLoanDetailsButton extends StatefulWidget {
  const HomeLoanDetailsButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  State<HomeLoanDetailsButton> createState() => _HomeLoanDetailsButtonState();
}

class _HomeLoanDetailsButtonState extends State<HomeLoanDetailsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 240),
    );
  }

  void _syncAnimation() {
    if (_isPressed || _isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() {
      _isPressed = value;
    });
    _syncAnimation();
  }

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() {
      _isHovered = value;
    });
    _syncAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = Curves.easeOut.transform(_animationController.value);
          final activeScale = _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0);
          final scale = 1 + ((activeScale - 1) * progress);
          final startColor = Color.lerp(
            AppColors.buttonStart,
            AppColors.secondary,
            progress,
          )!;
          final textColor = enabled
              ? Colors.white
              : Colors.white.withValues(alpha: 0.80);

          return Transform.scale(
            scale: enabled ? scale : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [startColor, AppColors.buttonEnd],
                      )
                    : null,
                color: enabled ? null : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.28)
                      : Colors.white.withValues(alpha: 0.18),
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.buttonShadow.withValues(
                            alpha: 0.35 + (progress * 0.25),
                          ),
                          blurRadius: 12 + (progress * 8),
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: enabled ? (_) => _setPressed(true) : null,
                  onTapUp: enabled ? (_) => _setPressed(false) : null,
                  onTapCancel: enabled ? () => _setPressed(false) : null,
                  onHover: enabled ? _setHovered : null,
                  borderRadius: BorderRadius.circular(100),
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  hoverColor: Colors.white.withValues(alpha: 0.08),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'view_details'.tr,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.translate(
                            offset: Offset(progress * 3, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
