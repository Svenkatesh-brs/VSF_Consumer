import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/common/app_loading.dart';
import '../models/emi_schedule_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

class EmiScheduleScreen extends StatefulWidget {
  const EmiScheduleScreen({super.key});

  @override
  State<EmiScheduleScreen> createState() => _EmiScheduleScreenState();
}

class _EmiScheduleScreenState extends State<EmiScheduleScreen> {
  late final LoanDashboardProvider controller;

  bool _isExiting = false;

  // ------------------------------------------------------------
  // EXPANSION STATE
  //
  // Keyed by each EMI's index in the model's list so cards expand
  // and collapse independently. Only the next upcoming EMI is
  // expanded initially; all others start collapsed.
  // ------------------------------------------------------------

  final Set<int> _expandedIndexes = {};
  bool _expansionInitialized = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // Reuses the live provider (and its already-fetched
    // EmiScheduleModel) from the Loan Dashboard route.
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
  // STATUS BADGE
  //
  // Shows the raw status exactly as returned by the API
  // (Paid / Partial / Overdue / Pending).
  // ============================================================

  Color _statusColor(String status) {
    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'paid') {
      return AppColors.buttonStart;
    }

    if (lowerStatus == 'partial') {
      return AppColors.secondary;
    }

    if (lowerStatus == 'overdue') {
      return AppColors.error;
    }

    return AppColors.buttonEnd;
  }

  Widget _buildStatusBadge(String status) {
    final badgeColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeColor.withValues(alpha: 0.16)),
      ),
      child: Text(
        status.isEmpty ? '-' : status.toUpperCase(),
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
  // EMI CARD
  //
  // Zero / missing numeric components are omitted rather than
  // invented; dates go through the shared epoch formatter.
  // ============================================================

  void _toggleCard(int index) {
    setState(() {
      if (_expandedIndexes.contains(index)) {
        _expandedIndexes.remove(index);
      } else {
        _expandedIndexes.add(index);
      }
    });
  }

  String _formatEmiNumber(int index) {
    return 'EMI ${(index + 1).toString().padLeft(2, '0')}';
  }

  int? _firstUpcomingIndex(EmiScheduleModel schedule) {
    for (var i = 0; i < schedule.emis.length; i++) {
      if (schedule.emis[i].isUpcoming) {
        return i;
      }
    }

    return null;
  }

  // ============================================================
  // TIMELINE DOT
  // ============================================================

  Widget _buildTimelineDot({
    required String status,
    required bool isNextUpcoming,
  }) {
    if (isNextUpcoming) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.buttonStart, AppColors.buttonEnd],
          ),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.buttonEnd.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }

    final isPending = status.toLowerCase() == 'pending';
    final color = _statusColor(status);

    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPending ? Colors.white : color,
        border: Border.all(
          color: isPending
              ? AppColors.tintColor
              : color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // TIMELINE ITEM
  // ------------------------------------------------------------
  // A dot beside the EMI card. The connector line itself lives
  // in _buildTimelineGroup (a Stack), so cards can grow and
  // shrink freely without constraining the rail's height.
  // ============================================================

  Widget _buildTimelineItem({
    required EmiItem emi,
    required int index,
    required bool isNextUpcoming,
  }) {
    final isExpanded = _expandedIndexes.contains(index);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.center,
              child: _buildTimelineDot(
                status: emi.status,
                isNextUpcoming: isNextUpcoming,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildEmiCard(
            emi: emi,
            index: index,
            isNextUpcoming: isNextUpcoming,
            isExpanded: isExpanded,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TIMELINE GROUP
  // ------------------------------------------------------------
  // Renders one continuous connector down the 26px gutter and
  // stacks the timeline items on top of it.
  // ============================================================

  Widget _buildTimelineGroup(List<Widget> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );

    if (items.length < 2) {
      return content;
    }

    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: AppColors.tintColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        content,
      ],
    );
  }

  // ============================================================
  // EMI CARD
  // ------------------------------------------------------------
  // Collapsible card; tapping the card toggles the numeric
  // break-up via AnimatedSize. The NEXT upcoming EMI carries
  // a subtle gradient highlight.
  // ============================================================

  Widget _buildEmiCard({
    required EmiItem emi,
    required int index,
    required bool isNextUpcoming,
    required bool isExpanded,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNextUpcoming
              ? [
                  AppColors.buttonEnd.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.85),
                ]
              : [
                  Colors.white.withValues(alpha: 0.80),
                  Colors.white.withValues(alpha: 0.48),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNextUpcoming
              ? AppColors.buttonEnd.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleCard(index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(
                    emi: emi,
                    index: index,
                    isNextUpcoming: isNextUpcoming,
                    isExpanded: isExpanded,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? _buildExpandedDetails(emi)
                        : const SizedBox(width: double.infinity, height: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required EmiItem emi,
    required int index,
    required bool isNextUpcoming,
    required bool isExpanded,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isNextUpcoming
                ? AppColors.buttonEnd.withValues(alpha: 0.12)
                : AppColors.lightBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.event_note_outlined,
            size: 19,
            color: isNextUpcoming ? AppColors.buttonEnd : AppColors.lightBlue,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _formatEmiNumber(index),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),

                  if (isNextUpcoming) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
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
                        'NEXT',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 3),

              Text(
                controller.formatDateMs(emi.dueDateMs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),

              if (emi.id.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  emi.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(emi.emiAmount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.lightBlue,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(emi.status),

                const SizedBox(width: 5),

                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.lightBlack,
                  ),
                ),
              ],
            ),

            if (emi.daysOverdue > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${emi.daysOverdue} '
                  '${emi.daysOverdue == 1 ? 'day' : 'days'} '
                  'overdue',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(EmiItem emi) {
    final detailRows = <Widget>[
      _buildInfoRow(
        label: 'Principal',
        value: _formatAmount(emi.principalComponent),
      ),
      _buildInfoRow(
        label: 'Interest',
        value: _formatAmount(emi.interestComponent),
      ),
      if (emi.insuranceComponent > 0)
        _buildInfoRow(
          label: 'Insurance',
          value: _formatAmount(emi.insuranceComponent),
        ),
      if (emi.principalOutstanding > 0)
        _buildInfoRow(
          label: 'Outstanding',
          value: _formatAmount(emi.principalOutstanding),
        ),
      _buildInfoRow(label: 'LPC Due', value: _formatAmount(emi.lpcDue)),
      _buildInfoRow(label: 'Total Paid', value: _formatAmount(emi.totalPaid)),
      _buildInfoRow(
        label: 'Remaining',
        value: _formatAmount(emi.remainingAmount),
      ),
      if (emi.lastPaymentDateMs != null)
        _buildInfoRow(
          label: 'Last Payment',
          value: controller.formatDateMs(emi.lastPaymentDateMs),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.tintColor.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.tintColor.withValues(alpha: 0.55),
          ),
        ),
        child: Column(children: detailRows),
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.black45,
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
              Icons.event_note_outlined,
              size: 42,
              color: AppColors.lightBlue.withValues(alpha: 0.45),
            ),

            const SizedBox(height: 14),

            const Text(
              'No EMI records found.',
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
  // Shown when the shared provider has no EMI schedule yet and
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
  //
  // EMIs are grouped with the model's own helpers: past =
  // Paid / Partial / Overdue, upcoming = Pending. Original API
  // order is preserved inside each group; nothing is filtered
  // or duplicated.
  // ============================================================

  List<Widget> _buildScheduleSections(
    EmiScheduleModel schedule, {
    required int? nextUpcomingIndex,
  }) {
    final pastEmis = schedule.emis.where((emi) => emi.isPast).toList();

    final upcomingEmis = schedule.emis.where((emi) => emi.isUpcoming).toList();

    final pastIndices = pastEmis
        .map((emi) => schedule.emis.indexOf(emi))
        .toList();

    final upcomingIndices = upcomingEmis
        .map((emi) => schedule.emis.indexOf(emi))
        .toList();

    final sections = <Widget>[];

    if (pastEmis.isNotEmpty) {
      sections.add(_buildSectionLabel('Past EMIs'));

      sections.add(
        _buildTimelineGroup([
          for (var i = 0; i < pastEmis.length; i++)
            _buildTimelineItem(
              emi: pastEmis[i],
              index: pastIndices[i],
              isNextUpcoming: false,
            ),
        ]),
      );
    }

    if (upcomingEmis.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 14));
      }

      sections.add(_buildSectionLabel('Upcoming EMIs'));

      sections.add(
        _buildTimelineGroup([
          for (var i = 0; i < upcomingEmis.length; i++)
            _buildTimelineItem(
              emi: upcomingEmis[i],
              index: upcomingIndices[i],
              isNextUpcoming: upcomingIndices[i] == nextUpcomingIndex,
            ),
        ]),
      );
    }

    return sections;
  }

  // ============================================================
  // SCHEDULE SUMMARY
  // ------------------------------------------------------------
  // TOTAL / PAID / UPCOMING metrics with an overdue pill when
  // any EMI is overdue.
  // ============================================================

  Widget _buildScheduleSummary(EmiScheduleModel schedule) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.85),
            AppColors.tintColor.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryMetric(value: '${schedule.totalCount}', label: 'TOTAL'),
              _summaryMetric(value: '${schedule.paidCount}', label: 'PAID'),
              _summaryMetric(
                value: '${schedule.upcomingCount}',
                label: 'UPCOMING',
              ),
            ],
          ),

          if (schedule.overdueCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.16),
                ),
              ),
              child: Text(
                '${schedule.overdueCount} '
                '${schedule.overdueCount == 1 ? 'EMI' : 'EMIs'} '
                'overdue',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryMetric({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.lightBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(EmiScheduleModel schedule) {
    if (schedule.isEmpty) {
      return 'Payment schedule';
    }

    final parts = <String>[
      if (schedule.paidCount > 0) '${schedule.paidCount} paid',
      if (schedule.overdueCount > 0) '${schedule.overdueCount} overdue',
      if (schedule.upcomingCount > 0) '${schedule.upcomingCount} upcoming',
    ];

    if (parts.isEmpty) {
      return '${schedule.totalCount} '
          'record${schedule.totalCount == 1 ? '' : 's'}';
    }

    return parts.join(' · ');
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
            final schedule = controller.emiSchedule.value;

            if (schedule == null) {
              final isLoading = controller.isLoading.value;

              if (!isLoading && controller.errorMessage.value != null) {
                return _buildErrorView();
              }

              return const AppLoading(
                message: 'Loading EMI schedule',
                subtitle: 'Please wait while we fetch your payment schedule.',
                size: 300,
              );
            }

            final nextUpcomingIndex = _firstUpcomingIndex(schedule);

            if (!_expansionInitialized) {
              _expansionInitialized = true;

              if (nextUpcomingIndex != null) {
                _expandedIndexes
                  ..clear()
                  ..add(nextUpcomingIndex);
              }
            }

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
                  // ============================================
                  // HEADER
                  // ENTRY LEFT - 0ms
                  // EXIT RIGHT - 0ms
                  // ============================================

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
                                  'EMI Schedule',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.lightBlue,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(
                                  _buildSubtitle(schedule),
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

                  // ============================================
                  // SCHEDULE
                  // ENTRY LEFT - 80ms
                  // EXIT RIGHT - 80ms
                  // ============================================
                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection.toRight,
                    delay: const Duration(milliseconds: 80),
                    child: ScreenContentTransition(
                      direction: ContentTransitionDirection.fromLeft,
                      delay: const Duration(milliseconds: 80),
                      child: schedule.isEmpty
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              width: double.infinity,
                              child: _buildEmptyState(),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildScheduleSummary(schedule),
                                ..._buildScheduleSections(
                                  schedule,
                                  nextUpcomingIndex: nextUpcomingIndex,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
          }),
        ),
      ),
    );
  }
}
