import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/loan_dashboard/profile_drawer.dart';
import '../widgets/loan_dashboard/pay_emi_button.dart';
import '../providers/loan_dashboard_provider.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';
import '../widgets/loan_dashboard/loan_overview_card.dart';
import '../widgets/loan_dashboard/loan_quick_actions.dart';
import '../widgets/common/app_loading.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  late final LoanDashboardProvider controller;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

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
  // NAVIGATE WITH EXIT WAVE
  //
  // Shared by every forward navigation from this screen so the
  // exit/enter waves stay identical.
  // ============================================================

  Future<void> _navigateTo(String route) async {
    if (_isExiting) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isExiting = true;
    });

    // ----------------------------------------------------------
    // Wait for the dashboard exit wave to complete.
    // ----------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    await Get.toNamed(route);

    if (!mounted) {
      return;
    }

    // Reset the exit state so the content slides back in
    // when the user returns from the next screen.
    setState(() {
      _isExiting = false;
    });
  }

  // ============================================================
  // OPEN LOAN DETAILS
  // ============================================================

  Future<void> _openLoanDetails() {
    return _navigateTo(AppRoutes.loanDetails);
  }

  // ============================================================
  // OPEN TRANSACTIONS
  // ============================================================

  Future<void> _openTransactions() {
    return _navigateTo(AppRoutes.transactions);
  }

  // ============================================================
  // OPEN EMI SCHEDULE
  // ============================================================

  Future<void> _openEmiSchedule() {
    return _navigateTo(AppRoutes.emiSchedule);
  }

  // ============================================================
  // OPEN COMPLAINT
  // ============================================================

  Future<void> _openComplaint() {
    return _navigateTo(AppRoutes.complaint);
  }

  // ============================================================
  // OPEN CONTACT UPDATE
  // ============================================================

  Future<void> _openContactUpdate() {
    return _navigateTo(AppRoutes.contactUpdate);
  }

  // ============================================================
  // OPEN HELP & SUPPORT
  // ============================================================

  Future<void> _openHelp() {
    return _navigateTo(AppRoutes.help);
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================


  // ============================================================
  // PROFILE DRAWER
  // ============================================================

  void _openProfileDrawer() {
    ProfileDrawer.show(context);
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
            if (controller.selectedLoan.value == null) {
              return const AppLoading(
                message: 'Loading loan dashboard',
                subtitle: 'Please wait while we fetch your loan information.',
                size: 300,
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 115),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HEADER
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

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Loan Dashboard',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.lightBlue,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Manage your loan at a glance',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: _openProfileDrawer,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.lightBlue,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // LOAN OVERVIEW
                      // ==================================================
                      ScreenContentExit(
                        isExiting: _isExiting,
                        direction: ContentExitDirection.toRight,
                        delay: const Duration(milliseconds: 80),
                        child: ScreenContentTransition(
                          direction: ContentTransitionDirection.fromLeft,
                          delay: const Duration(milliseconds: 80),
                          child: GestureDetector(
                            onTap: _openLoanDetails,
                            behavior: HitTestBehavior.opaque,
                            child: LoanOverviewCard(
                              status: controller.status,
                              vehicleNumber: controller.vehicleNumber,
                              borrowerName: controller.borrowerName,
                              loanAmount: controller.amount,
                              outstandingAmount: controller.outstandingAmount,
                              emiAmount: controller.emiAmount,
                              nextEmiDate: controller.nextEmiDueDate,
                              repaymentProgress: controller.repaymentProgress,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // NEW QUICK ACTIONS
                      // ==================================================
                      ScreenContentExit(
                        isExiting: _isExiting,
                        direction: ContentExitDirection.toRight,
                        delay: const Duration(milliseconds: 220),
                        child: ScreenContentTransition(
                          direction: ContentTransitionDirection.fromLeft,
                          delay: const Duration(milliseconds: 220),
                          child: LoanQuickActions(
                            onEmiScheduleTap: _openEmiSchedule,
                            onTransactionsTap: _openTransactions,
                            onContactUpdateTap: _openContactUpdate,
                            onComplaintsTap: _openComplaint,
                            onHelpTap: _openHelp,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ========================================================
                // PAY EMI BUTTON
                // ========================================================
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: SafeArea(
                    child: PayEmiButton(
                      // Disabled only for Inactive
                      // loans (no EMI due). Every
                      // other backend status maps
                      // to Active per the shared
                      // display convention.
                      isCompleted:
                          controller.status.toLowerCase() == 'inactive',
                      onTap: () {
                        _navigateTo(AppRoutes.payEmi);
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
