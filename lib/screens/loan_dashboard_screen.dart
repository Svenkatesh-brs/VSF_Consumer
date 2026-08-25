import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/loan_dashboard/pay_emi_button.dart';
import '../providers/loan_dashboard_provider.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';
import '../widgets/loan_dashboard/loan_overview_card.dart';
import '../widgets/loan_dashboard/loan_quick_actions.dart';

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

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

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

  void _onQuickActionTap(String action) {
    _showTemporaryMessage(action, '$action will be available soon.');
  }

  // ============================================================
  // TEMPORARY MESSAGE
  // ============================================================

  void _showTemporaryMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      colorText: AppColors.lightBlue,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================
  // PROFILE DRAWER
  // ============================================================

  void _openProfileDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _buildProfileDrawer(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: slideAnimation, child: child);
      },
    );
  }

  // ============================================================
  // PROFILE DRAWER UI
  // ============================================================

  Widget _buildProfileDrawer() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 30,
              offset: const Offset(-8, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======================================================
                // DRAWER HEADER
                // ======================================================

                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.buttonEnd.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.lightBlue,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightBlue,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage your account',
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
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.lightBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ======================================================
                // PROFILE INFORMATION
                // ======================================================
                _buildProfileInfoCard(),

                const SizedBox(height: 22),

                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 10),

                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Get.back();

                    _showTemporaryMessage(
                      'My Profile',
                      'Profile details will be available soon.',
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Get.back();

                    _openHelp();
                  },
                ),

                const Spacer(),

                // ======================================================
                // LOGOUT
                // ======================================================
                _buildLogoutItem(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE INFO CARD
  // ============================================================

  Widget _buildProfileInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlue.withValues(alpha: 0.06),
            AppColors.buttonEnd.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.lightBlue,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.borrowerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightBlue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consumer account',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
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
  // DRAWER ITEM
  // ============================================================

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 21, color: AppColors.lightBlue),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT ITEM
  // ============================================================

  Widget _buildLogoutItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.back();

          _showTemporaryMessage('Logout', 'Logout will be implemented later.');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.07)),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 21, color: Colors.redAccent),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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
                              vehicleNumber:
                                  controller.vehicleNumber,
                              borrowerName:
                                  controller.borrowerName,
                              loanAmount: controller.amount,
                              outstandingAmount: controller
                                  .outstandingAmount,
                              emiAmount:
                                  controller.emiAmount,
                              nextEmiDate: controller
                                  .nextEmiDueDate,
                              repaymentProgress: controller
                                  .repaymentProgress,
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
                            onTransactionsTap: () {
                              _openTransactions();
                            },
                            onContactUpdateTap: () {
                              _openContactUpdate();
                            },
                            onComplaintsTap: () {
                              _openComplaint();
                            },
                            onHelpTap: _openHelp,
                            onEmiScheduleTap: () {
                              _openEmiSchedule();
                            },
                            onReceiptsTap: () {
                              _onQuickActionTap('Receipts');
                            },
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
                    child:                     PayEmiButton(
                      // Disabled only for Inactive
                      // loans (no EMI due). Every
                      // other backend status maps
                      // to Active per the shared
                      // display convention.
                      isCompleted:
                          controller.status.toLowerCase() ==
                              'inactive',
                      onTap: () {
                        _showTemporaryMessage(
                          'Pay EMI',
                          'Payment will be available soon.',
                        );
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
