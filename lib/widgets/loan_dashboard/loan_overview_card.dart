import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class LoanOverviewCard extends StatefulWidget {
  final String status;
  final String vehicleNumber;
  final String borrowerName;
  final double loanAmount;
  final double outstandingAmount;
  final double emiAmount;
  final String nextEmiDate;
  final int totalEmis;
  final int paidEmis;
  final int upcomingEmis;
  final int overdueEmis;

  // Authoritative progress from the API
  // (totalEMIPaid / totalEMI) as a 0.0 - 1.0 fraction.
  // When null the card falls back to deriving progress
  // from the amounts.
  final double? repaymentProgress;

  const LoanOverviewCard({
    super.key,
    required this.status,
    required this.vehicleNumber,
    required this.borrowerName,
    required this.loanAmount,
    required this.outstandingAmount,
    required this.emiAmount,
    required this.nextEmiDate,
    required this.totalEmis,
    required this.paidEmis,
    required this.upcomingEmis,
    required this.overdueEmis,
    this.repaymentProgress,
  });

  @override
  State<LoanOverviewCard> createState() => _LoanOverviewCardState();
}

class _LoanOverviewCardState extends State<LoanOverviewCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _glowController;
  late final AnimationController _progressController;
  late final AnimationController _overdueController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  // ============================================================
  // REPAYMENT PROGRESS
  // ============================================================

  double get _repaymentProgress {
    if (widget.repaymentProgress != null) {
      return widget.repaymentProgress!.clamp(0.0, 1.0);
    }

    if (widget.loanAmount <= 0) {
      return 0.0;
    }

    final progress = 1.0 - (widget.outstandingAmount / widget.loanAmount);

    return progress.clamp(0.0, 1.0);
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get _isCompleted {
    return widget.status.toLowerCase() == 'completed';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // ENTRY ANIMATION
    // ----------------------------------------------------------

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    // ----------------------------------------------------------
    // BACKGROUND GLOW
    // ----------------------------------------------------------

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // ----------------------------------------------------------
    // PROGRESS
    // ----------------------------------------------------------

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // ----------------------------------------------------------
    // OVERDUE PULSE
    // ----------------------------------------------------------

    _overdueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (widget.overdueEmis > 0) {
      _overdueController.repeat(reverse: true);
    }

    // Start card animation.
    _entryController.forward();

    // Start progress after the card begins appearing.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      _progressController.forward();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _overdueController.dispose();

    super.dispose();
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  // ============================================================
  // STATUS DOT
  // ============================================================

  Widget _buildStatusDot() {
    return _PulsingStatusDot(isCompleted: _isCompleted);
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.75, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.15, 0.70, curve: Curves.easeOutBack),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusDot(),
              const SizedBox(width: 7),
              Text(
                widget.status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT ITEM
  // ============================================================

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required double delay,
  }) {
    final end = (delay + 0.30).clamp(0.0, 1.0);

    return Expanded(
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: Interval(delay, end, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _entryController,
                  curve: Interval(
                    delay,
                    (delay + 0.40).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmiSummary() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.42, 0.85, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _buildEmiSummaryItem(
              label: 'TOTAL EMIs',
              value: widget.totalEmis.toString(),
            ),
            _buildEmiSummaryDivider(),
            _buildEmiSummaryItem(
              label: 'PAID',
              value: widget.paidEmis.toString(),
            ),
            _buildEmiSummaryDivider(),
            _buildEmiSummaryItem(
              label: 'UPCOMING',
              value: widget.upcomingEmis.toString(),
            ),
            _buildEmiSummaryDivider(),
            _buildEmiSummaryItem(
              label: 'OVERDUE',
              value: widget.overdueEmis.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiSummaryItem({required String label, required String value}) {
    final isOverdue = label == 'OVERDUE' && widget.overdueEmis > 0;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOverdue)
            AnimatedBuilder(
              animation: _overdueController,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_overdueController.value);

                final pulse = 1.0 + (t * 0.045);

                final glow = 0.25 + (t * 0.45);

                return Transform.scale(
                  scale: pulse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: glow),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isOverdue
                  ? Colors.redAccent.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiSummaryDivider() {
    return Container(
      width: 1,
      height: 25,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  // ============================================================
  // REPAYMENT PROGRESS
  // ============================================================

  Widget _buildRepaymentProgress() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final animationValue = Curves.easeOutCubic.transform(
          _progressController.value,
        );

        final progress = _repaymentProgress * animationValue;

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Repayment Progress',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.buttonEnd],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final angle = _glowController.value * math.pi * 2;

        final topGlowX = math.sin(angle) * 18;

        final topGlowY = math.cos(angle) * 14;

        final bottomGlowX = math.cos(angle * 0.8) * 14;

        final bottomGlowY = math.sin(angle * 0.8) * 18;

        final shinePosition = -100 + (_glowController.value * 420);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightBlue.withValues(alpha: 0.17),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      // ==================================================
                      // MAIN CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1C3478),
                              Color(0xFF283D91),
                              Color(0xFF4C4190),
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ==========================================
                            // HEADER
                            // ==========================================

                            Row(
                              children: [
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'LOAN OVERVIEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ==========================================
                            // VEHICLE + BORROWER
                            // ==========================================
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: _entryController,
                                  curve: const Interval(
                                    0.15,
                                    0.70,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.vehicleNumber,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.borrowerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.62,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 19),

                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),

                            const SizedBox(height: 16),

                            // ==========================================
                            // EMI SUMMARY
                            // ==========================================
                            _buildEmiSummary(),

                            const SizedBox(height: 14),

                            // ==========================================
                            // FINANCIAL GRID
                            // ==========================================
                            Row(
                              children: [
                                _buildStatItem(
                                  icon: Icons.currency_rupee_rounded,
                                  label: 'LOAN AMOUNT',
                                  value: _formatAmount(widget.loanAmount),
                                  delay: 0.28,
                                ),
                                const SizedBox(width: 10),
                                _buildStatItem(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'OUTSTANDING',
                                  value: _formatAmount(
                                    widget.outstandingAmount,
                                  ),
                                  delay: 0.34,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                _buildStatItem(
                                  icon: Icons.payments_outlined,
                                  label: 'EMI AMOUNT',
                                  value: _formatAmount(widget.emiAmount),
                                  delay: 0.40,
                                ),
                                const SizedBox(width: 10),
                                _buildStatItem(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'NEXT EMI',
                                  value: widget.nextEmiDate,
                                  delay: 0.46,
                                ),
                              ],
                            ),

                            const SizedBox(height: 17),

                            // ==========================================
                            // REPAYMENT PROGRESS
                            // ==========================================
                            _buildRepaymentProgress(),
                          ],
                        ),
                      ),

                      // ==================================================
                      // TOP RIGHT GLOW
                      // ==================================================
                      Positioned(
                        top: -75 + topGlowY,
                        right: -60 + topGlowX,
                        child: IgnorePointer(
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // BOTTOM LEFT GLOW
                      // ==================================================
                      Positioned(
                        bottom: -100 + bottomGlowY,
                        left: -80 + bottomGlowX,
                        child: IgnorePointer(
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.buttonEnd.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ==================================================
                      // MOVING SHINE
                      // ==================================================
                      Positioned(
                        top: 0,
                        left: shinePosition,
                        child: IgnorePointer(
                          child: Container(
                            width: 80,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// PULSING STATUS DOT
// ================================================================

class _PulsingStatusDot extends StatefulWidget {
  final bool isCompleted;

  const _PulsingStatusDot({required this.isCompleted});

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.85 + (_controller.value * 0.25);

        final color = widget.isCompleted
            ? AppColors.primary
            : AppColors.buttonStart;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: 0.35 + (_controller.value * 0.25),
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
