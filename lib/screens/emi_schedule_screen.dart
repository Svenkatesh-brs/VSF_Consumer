import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/emi_schedule_model.dart';
import '../providers/loan_dashboard_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

class EmiScheduleScreen extends StatefulWidget {
  const EmiScheduleScreen({super.key});

  @override
  State<EmiScheduleScreen> createState() =>
      _EmiScheduleScreenState();
}

class _EmiScheduleScreenState
    extends State<EmiScheduleScreen> {
  late final LoanDashboardProvider controller;

  bool _isExiting = false;

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

  // ============================================================
  // STATUS BADGE
  //
  // Shows the raw status exactly as returned by the API
  // (Paid / Partial / Overdue / Pending).
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final lowerStatus = status.toLowerCase();

    final Color badgeColor;

    if (lowerStatus == 'paid') {
      badgeColor = AppColors.buttonStart;
    } else if (lowerStatus == 'partial') {
      badgeColor = AppColors.secondary;
    } else if (lowerStatus == 'overdue') {
      badgeColor = AppColors.error;
    } else {
      badgeColor = AppColors.buttonEnd;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.16),
        ),
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

  Widget _buildEmiCard(EmiItem emi) {
    final detailRows = <Widget>[
      _buildInfoRow(
        label: 'Principal',
        value:
            _formatAmount(emi.principalComponent),
      ),
      _buildInfoRow(
        label: 'Interest',
        value:
            _formatAmount(emi.interestComponent),
      ),
      if (emi.insuranceComponent > 0)
        _buildInfoRow(
          label: 'Insurance',
          value: _formatAmount(
              emi.insuranceComponent),
        ),
      if (emi.principalOutstanding > 0)
        _buildInfoRow(
          label: 'Outstanding',
          value: _formatAmount(
              emi.principalOutstanding),
        ),
      _buildInfoRow(
        label: 'LPC Due',
        value: _formatAmount(emi.lpcDue),
      ),
      _buildInfoRow(
        label: 'Total Paid',
        value: _formatAmount(emi.totalPaid),
      ),
      _buildInfoRow(
        label: 'Remaining',
        value:
            _formatAmount(emi.remainingAmount),
      ),
      if (emi.lastPaymentDateMs != null)
        _buildInfoRow(
          label: 'Last Payment',
          value: controller.formatDateMs(
              emi.lastPaymentDateMs),
        ),
    ];

    return Container(
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
          // TOP ROW
          // ------------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  size: 19,
                  color: AppColors.lightBlue,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.formatDateMs(
                          emi.dueDateMs),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),

                    if (emi.id.isNotEmpty) ...[
                      const SizedBox(height: 4),

                      Text(
                        emi.id,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(emi.emiAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightBlue,
                    ),
                  ),

                  const SizedBox(height: 4),

                  _buildStatusBadge(emi.status),

                  if (emi.daysOverdue > 0)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets
                            .symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error
                              .withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(
                                  100),
                        ),
                        child: Text(
                          '${emi.daysOverdue} '
                                  '${emi.daysOverdue == 1 ? 'day' : 'days'} '
                              'overdue',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            height: 1,
            color: AppColors.lightBlue
                .withValues(alpha: 0.07),
          ),

          const SizedBox(height: 4),

          ...detailRows,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
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
      padding: const EdgeInsets.only(
        bottom: 10,
        left: 2,
      ),
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
              color: AppColors.lightBlue
                  .withValues(alpha: 0.45),
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
  //
  // EMIs are grouped with the model's own helpers: past =
  // Paid / Partial / Overdue, upcoming = Pending. Original API
  // order is preserved inside each group; nothing is filtered
  // or duplicated.
  // ============================================================

  List<Widget> _buildScheduleSections(
    EmiScheduleModel schedule,
  ) {
    final pastEmis = schedule.emis
        .where((emi) => emi.isPast)
        .toList();

    final upcomingEmis = schedule.emis
        .where((emi) => emi.isUpcoming)
        .toList();

    final sections = <Widget>[];

    if (pastEmis.isNotEmpty) {
      sections.add(
        _buildSectionLabel('Past EMIs'),
      );

      sections.addAll(
        pastEmis.map(_buildEmiCard),
      );
    }

    if (upcomingEmis.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add(
          const SizedBox(height: 14),
        );
      }

      sections.add(
        _buildSectionLabel('Upcoming EMIs'),
      );

      sections.addAll(
        upcomingEmis.map(_buildEmiCard),
      );
    }

    return sections;
  }

  String _buildSubtitle(EmiScheduleModel schedule) {
    if (schedule.isEmpty) {
      return 'Payment schedule';
    }

    final parts = <String>[
      if (schedule.paidCount > 0)
        '${schedule.paidCount} paid',
      if (schedule.overdueCount > 0)
        '${schedule.overdueCount} overdue',
      if (schedule.upcomingCount > 0)
        '${schedule.upcomingCount} upcoming',
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
            final schedule =
                controller.emiSchedule.value;

            if (schedule == null) {
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

            return SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 40),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER
                  // ENTRY LEFT - 0ms
                  // EXIT RIGHT - 0ms
                  // ============================================

                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection
                        .toRight,
                    delay: Duration.zero,
                    child: ScreenContentTransition(
                      direction:
                          ContentTransitionDirection
                              .fromLeft,
                      delay: Duration.zero,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                      alpha: 0.75),
                              shape:
                                  BoxShape.circle,
                              border: Border.all(
                                color: Colors.white
                                    .withValues(
                                        alpha:
                                            0.65),
                              ),
                            ),
                            child: IconButton(
                              padding:
                                  EdgeInsets.zero,
                              onPressed: _goBack,
                              icon: const Icon(
                                Icons
                                    .arrow_back_rounded,
                                size: 21,
                                color: AppColors
                                    .lightBlue,
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'EMI Schedule',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    color: AppColors
                                        .lightBlue,
                                  ),
                                ),

                                const SizedBox(
                                    height: 2),

                                Text(
                                  _buildSubtitle(
                                      schedule),
                                  style:
                                      const TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                    color: Colors
                                        .black45,
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
                    direction: ContentExitDirection
                        .toRight,
                    delay: const Duration(
                        milliseconds: 80),
                    child:
                        ScreenContentTransition(
                      direction:
                          ContentTransitionDirection
                              .fromLeft,
                      delay: const Duration(
                          milliseconds: 80),
                      child: schedule.isEmpty
                          ? SizedBox(
                              height: MediaQuery.of(
                                          context)
                                      .size
                                      .height *
                                  0.5,
                              width:
                                  double.infinity,
                              child:
                                  _buildEmptyState(),
                            )
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children:
                                  _buildScheduleSections(
                                      schedule),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
