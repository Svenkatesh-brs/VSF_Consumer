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
        return 'Pending';

      case ComplaintModel.approved:
        return 'Approved';

      case ComplaintModel.rejected:
        return 'Rejected';

      default:
        return 'Unknown';
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
              const Text(
                'Your Complaints',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Track the complaints you have submitted.',
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
          () => controller.totalComplaints.value > 0
              ? Container(
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
              : const SizedBox.shrink(),
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
    if (controller.isLoading.value &&
        controller.complaints.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.errorMessage.value != null &&
        controller.complaints.isEmpty) {
      return _buildErrorState();
    }

    if (controller.complaints.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        ...controller.complaints.map(
          _buildComplaintCard,
        ),

        const SizedBox(height: 8),

        _buildPagination(),
      ],
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.58,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list_rounded,
            size: 19,
            color: AppColors.lightBlue,
          ),

          const SizedBox(width: 8),

          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const Spacer(),

          Obx(
            () => DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value:
                    controller.selectedStatus.value,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ComplaintModel.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: ComplaintModel.approved,
                    child: Text('Approved'),
                  ),
                  DropdownMenuItem(
                    value: ComplaintModel.rejected,
                    child: Text('Rejected'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.setStatus(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLAINT CARD
  // ============================================================

  Widget _buildComplaintCard(
    ComplaintModel complaint,
  ) {
    final statusColor =
        _statusColor(complaint.status);

    return Container(
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // TOP ROW
          // ------------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.11,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(
                    complaint.status,
                  ),
                  size: 21,
                  color: statusColor,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.lightBlue,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (complaint.id.isNotEmpty)
                      Text(
                        'ID: ${complaint.id}',
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),

              _buildStatusBadge(
                complaint.status,
              ),
            ],
          ),

          const SizedBox(height: 17),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------

          const Text(
            'Description',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            complaint.description.isNotEmpty
                ? complaint.description
                : '-',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // CREATED / UPDATED
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _buildDateInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created',
                  value: _formatDate(
                    complaint.createdAt,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildDateInfo(
                  icon: Icons.update_rounded,
                  label: 'Updated',
                  value: _formatDate(
                    complaint.updatedAt,
                  ),
                ),
              ),
            ],
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
              'Page ${controller.currentPage.value}',
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

        const Text(
          'No Complaints Found',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'There are no complaints under the '
          '${controller.selectedStatusLabel.toLowerCase()} status.',
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

        const Text(
          'Unable to Load Complaints',
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
            label: const Text(
              'Retry',
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