import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/complaint_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/app_colors.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({
    super.key,
  });

  @override
  State<ComplaintListScreen> createState() =>
      _ComplaintListScreenState();
}

class _ComplaintListScreenState
    extends State<ComplaintListScreen> {
  late final ComplaintProvider controller;
  final _expandedComplaintKeys = <String>{};

  @override
  void initState() {
    super.initState();

    controller = Get.find<ComplaintProvider>();

    // Load complaints when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.loadComplaints();
      }
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await controller.loadComplaints();
  }

  // ============================================================
  // DATE FORMATTER
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final localDate = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = localDate.day.toString().padLeft(2, '0');
    final month = months[localDate.month - 1];
    final year = localDate.year;

    final hour = localDate.hour == 0
        ? 12
        : localDate.hour > 12
            ? localDate.hour - 12
            : localDate.hour;

    final minute =
        localDate.minute.toString().padLeft(2, '0');

    final period =
        localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, '
        '$hour:$minute $period';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(int status) {
    switch (status) {
      case ComplaintModel.pending:
        return AppColors.buttonEnd;

      case ComplaintModel.approved:
        return AppColors.lightBlue;

      case ComplaintModel.rejected:
        return Colors.redAccent;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(int status) {
    switch (status) {
      case ComplaintModel.pending:
        return Icons.pending_actions_rounded;

      case ComplaintModel.approved:
        return Icons.check_circle_outline_rounded;

      case ComplaintModel.rejected:
        return Icons.cancel_outlined;

      default:
        return Icons.help_outline_rounded;
    }
  }

  // ============================================================
  // STATUS LABEL
  // ============================================================

  String _statusLabel(int status) {
    switch (status) {
      case ComplaintModel.pending:
        return 'pending'.tr;

      case ComplaintModel.approved:
        return 'resolved'.tr;

      case ComplaintModel.rejected:
        return 'rejected'.tr;

      default:
        return 'error'.tr;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Embedded as tab 2 of the Complaint
    // screen: no own background/header.
    return Obx(
      () => _buildBody(),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'your_complaints'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'track_complaints'.tr,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),

        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: controller.totalComplaints.value > 0
                ? Container(
                    key: const ValueKey('complaint-count'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${controller.totalComplaints.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-complaint-count')),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.lightBlue,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          30,
        ),
        children: [
          _buildIntro(),

          const SizedBox(height: 16),

          // ------------------------------------------
          // STATUS FILTER - ALWAYS VISIBLE IN EVERY
          // STATE (LOADING / ERROR / EMPTY / LIST).
          // ------------------------------------------

          _buildStatusFilter(),

          const SizedBox(height: 16),

          _buildListContent(),
        ],
      ),
    );
  }

  // ============================================================
  // LIST CONTENT
  //
  // Conditional area BELOW the always-visible status
  // filter: loading, error, empty or complaint cards.
  // ============================================================

  Widget _buildListContent() {
    late final Widget content;
    late final String state;

    if (controller.isLoading.value &&
        controller.complaints.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
      state = 'loading';
    } else if (controller.errorMessage.value != null &&
        controller.complaints.isEmpty) {
      content = _buildErrorState();
      state = 'error';
    } else if (controller.complaints.isEmpty) {
      content = _buildEmptyState();
      state = 'empty';
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...controller.complaints.asMap().entries.map(
                (entry) => _buildComplaintCard(
                  entry.value,
                  controller.totalComplaints.value -
                    entry.key -
                    ((controller.currentPage.value - 1) *
                      controller.recordsPerPage.value),
                ),
              ),
          const SizedBox(height: 8),
          _buildPagination(),
        ],
      );
      state =
          'list-${controller.currentPage.value}-${controller.selectedStatus.value}';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(state), child: content),
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _buildStatusFilter() {
    return Obx(() {
      final isAllSelected =
          controller.selectedStatus.value == ComplaintModel.all;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: isAllSelected
              ? AppColors.lightBlue.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAllSelected
                ? AppColors.lightBlue.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list_rounded, size: 19, color: AppColors.lightBlue),
            const SizedBox(width: 8),
            Text('status'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: controller.selectedStatus.value,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: [
                  DropdownMenuItem(value: ComplaintModel.all, child: Text('all'.tr)),
                  DropdownMenuItem(value: ComplaintModel.pending, child: Text('pending'.tr)),
                  DropdownMenuItem(value: ComplaintModel.approved, child: Text('resolved'.tr)),
                  DropdownMenuItem(value: ComplaintModel.rejected, child: Text('rejected'.tr)),
                ],
                onChanged: (value) {
                  if (value != null) controller.setStatus(value);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // COMPLAINT CARD
  // ============================================================

  Widget _buildComplaintCard(
    ComplaintModel complaint,
    int serialNumber,
  ) {
    final statusColor = _statusColor(complaint.status);
    final expansionKey = complaint.id.isNotEmpty
        ? complaint.id
        : 'complaint-$serialNumber';
    final isExpanded = _expandedComplaintKeys.contains(expansionKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(
              alpha: 0.84,
            ),
            Colors.white.withValues(
              alpha: 0.48,
            ),
          ],
        ),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.65,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedComplaintKeys.remove(expansionKey);
                } else {
                  _expandedComplaintKeys.add(expansionKey);
                }
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _statusIcon(complaint.status),
                    size: 21,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'complaint_number'.trParams({'number': '$serialNumber'}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${'created'.tr}: ${_formatDate(complaint.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                      if (!isExpanded) ...[
                        const SizedBox(height: 3),
                        Text(
                          complaint.description.trim().isNotEmpty
                              ? complaint.description.trim()
                              : '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(complaint.status),
                const SizedBox(width: 4),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: isExpanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightBlue,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildComplaintDetails(complaint),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintDetails(ComplaintModel complaint) {
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'description'.tr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            complaint.description.isNotEmpty ? complaint.description : '-',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                icon: Icons.category_outlined,
                label: complaint.issueTypeLabel,
              ),
              if (complaint.urgent)
                _buildDetailChip(
                  icon: Icons.priority_high_rounded,
                  label: 'urgent'.tr,
                  color: AppColors.buttonEnd,
                ),
            ],
          ),
          if (complaint.hasComments) ...[
            const SizedBox(height: 15),
            Text(
              'comments'.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: complaint.status == ComplaintModel.rejected
                    ? Colors.redAccent.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                complaint.comments.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'created'.tr,
                  value: _formatDate(complaint.createdAt),
                ),
              ),
              if (complaint.status != ComplaintModel.pending) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.support_agent_rounded,
                    label: 'response_date'.tr,
                    value: _formatDate(complaint.updatedAt),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    Color color = AppColors.lightBlue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(int status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // DATE INFO
  // ============================================================

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.45,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.lightBlue,
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    return Obx(
      () {
        final hasPrevious =
            controller.hasPreviousPage;

        final hasNext =
            controller.hasNextPage;

        if (!hasPrevious && !hasNext) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: hasPrevious
                  ? controller.previousPage
                  : null,
              icon: const Icon(
                Icons.chevron_left_rounded,
              ),
              color: AppColors.lightBlue,
            ),

            Text(
              'page'.trParams({'number': '${controller.currentPage.value}'}),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),

            IconButton(
              onPressed: hasNext
                  ? controller.nextPage
                  : null,
              icon: const Icon(
                Icons.chevron_right_rounded,
              ),
              color: AppColors.lightBlue,
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    // Rendered below the always-visible
    // status filter; no own scroll view.
    return Column(
      children: [
        const SizedBox(height: 70),

        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.lightBlue
                .withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inbox_outlined,
            size: 36,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'no_complaints'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          controller.selectedStatus.value == ComplaintModel.all
              ? 'no_complaints_message'.tr
              : 'no_filtered_complaints'.trParams({
                  'status': controller.selectedStatusLabel,
                }),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Colors.black.withValues(
              alpha: 0.52,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    final message =
        controller.errorMessage.value ??
            'Unable to load your complaints.';

    // Rendered below the always-visible
    // status filter; no own scroll view.
    return Column(
      children: [
        const SizedBox(height: 50),

        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 36,
            color: Colors.redAccent,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'unable_load_complaints'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Colors.black.withValues(
              alpha: 0.55,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Center(
          child: ElevatedButton.icon(
            onPressed: controller.loadComplaints,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(
              'retry'.tr,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.buttonEnd,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
