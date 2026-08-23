import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/complaint_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import 'complaint_list_screen.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({
    super.key,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen>
    with SingleTickerProviderStateMixin {
  late final ComplaintProvider controller;

  late final TextEditingController _descriptionController;
  late final FocusNode _descriptionFocusNode;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    controller = Get.find<ComplaintProvider>();

    _descriptionController = TextEditingController(
      text: controller.description.value,
    );

    _descriptionFocusNode = FocusNode();

    _descriptionController.addListener(() {
      controller.setDescription(
        _descriptionController.text,
      );
    });

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitComplaint() async {
    FocusScope.of(context).unfocus();

    final success = await controller.createComplaint();

    if (!mounted) {
      return;
    }

    if (success) {
      final complaint =
          controller.createdComplaint.value;

      _showSuccessDialog(complaint);
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog(
    ComplaintModel? complaint,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Complaint Submitted',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your complaint has been submitted successfully.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),

            if (complaint != null &&
                complaint.id.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Complaint ID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                complaint.id,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightBlue,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearCreateState();
            },
            child: const Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.buttonEnd,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (message.trim().isEmpty) {
      return;
    }

    Get.snackbar(
      'Complaint',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
    );
  }

  // ============================================================
  // ISSUE TYPE LABEL
  // ============================================================

  String _issueTypeLabel(int value) {
    switch (value) {
      case ComplaintCreateRequest.billingOrPayment:
        return 'Billing or Payment';

      case ComplaintCreateRequest.documents:
        return 'Documents';

      case ComplaintCreateRequest.serviceQuality:
        return 'Service Quality';

      case ComplaintCreateRequest.vehicleRelated:
        return 'Vehicle Related';

      case ComplaintCreateRequest.other:
        return 'Other';

      default:
        return 'Other';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildTabs(),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ==============================================
                  // TAB 1 - RAISE COMPLAINT
                  // (existing complaint creation form)
                  // ==============================================

                  Obx(
                    () {
                      final error =
                          controller.createErrorMessage.value;

                      if (error != null &&
                          error.isNotEmpty) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) {
                          if (mounted) {
                            controller.createErrorMessage.value =
                                null;

                            _showError(error);
                          }
                        });
                      }

                      return SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          28,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildIntro(),

                            const SizedBox(height: 20),

                            _buildComplaintCard(),

                            const SizedBox(height: 24),

                            _buildComplaintHistoryButton(),
                          ],
                        ),
                      );
                    },
                  ),

                  // ==============================================
                  // TAB 2 - MY COMPLAINTS
                  // (existing complaint list/history UI)
                  // ==============================================

                  const ComplaintListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.58,
          ),
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.92,
            ),
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.06,
                ),
                blurRadius: 8,
              ),
            ],
          ),
          labelColor: AppColors.lightBlue,
          unselectedLabelColor: Colors.black45,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text('Raise Complaint'),
                  ],
                ),
              ),
            ),
            Tab(
              height: 42,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text('My Complaints'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        20,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            color: AppColors.lightBlue,
          ),

          const SizedBox(width: 4),

          const Expanded(
            child: Text(
              'Complaints',
              style: TextStyle(
                fontSize: 20,
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
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Raise a Complaint',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Tell us about your issue and we will review your complaint.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: Colors.black.withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPLAINT CARD
  // ============================================================

  Widget _buildComplaintCard() {
    return Container(
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
          color: Colors.white.withValues(
            alpha: 0.60,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.report_problem_outlined,
            title: 'Complaint Details',
          ),

          const SizedBox(height: 20),

          _buildDescriptionField(),

          const SizedBox(height: 20),

          _buildIssueTypeSelector(),

          const SizedBox(height: 20),

          _buildUrgentSwitch(),

          const SizedBox(height: 24),

          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.lightBlue,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          minLines: 5,
          maxLines: 7,
          textInputAction:
              TextInputAction.newline,
          decoration: InputDecoration(
            hintText:
                'Describe your complaint...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Colors.black38,
            ),
            filled: true,
            fillColor: Colors.white.withValues(
              alpha: 0.55,
            ),
            contentPadding:
                const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.lightBlue,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ISSUE TYPE
  // ============================================================

  Widget _buildIssueTypeSelector() {
    return Obx(
      () {
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Issue Type',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int>(
              initialValue:
                  controller.selectedIssueType.value,
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Colors.white.withValues(
                  alpha: 0.55,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Colors.black.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color:
                        Colors.black.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.lightBlue,
                    width: 1.2,
                  ),
                ),
              ),
              items: List.generate(
                5,
                (index) {
                  final value = index + 1;

                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      _issueTypeLabel(value),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setIssueType(value);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // URGENT
  // ============================================================

  Widget _buildUrgentSwitch() {
    return Obx(
      () {
        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.45,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.buttonEnd
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 19,
                  color: AppColors.buttonEnd,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark as Urgent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Flag this complaint as urgent.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              Switch.adaptive(
                value:
                    controller.isUrgent.value,
                onChanged:
                    controller.setUrgent,
                activeTrackColor:
                    AppColors.buttonEnd,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return Obx(
      () {
        final isCreating =
            controller.isCreating.value;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                isCreating
                    ? null
                    : _submitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.buttonEnd,
              disabledBackgroundColor:
                  AppColors.buttonEnd.withValues(
                alpha: 0.50,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(100),
              ),
            ),
            child: isCreating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit Complaint',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ============================================================
  // COMPLAINT HISTORY
  // ============================================================

  Widget _buildComplaintHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          FocusScope.of(context).unfocus();

          _tabController.animateTo(1);
        },
        icon: const Icon(
          Icons.history_rounded,
          size: 18,
          color: AppColors.lightBlue,
        ),
        label: const Text(
          'View Complaint History',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.lightBlue,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize:
              const Size(double.infinity, 48),
          side: BorderSide(
            color: AppColors.lightBlue
                .withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}