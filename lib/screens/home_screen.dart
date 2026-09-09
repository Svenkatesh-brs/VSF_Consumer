import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/footer_version.dart';
import '../widgets/home/loan_card.dart';
import '../widgets/home/summary_card.dart';
import '../widgets/common/screen_transition.dart';
import '../widgets/common/screen_content_exit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider controller;

  bool _isExiting = false;
  int? _selectedLoanIndex;

  @override
  void initState() {
    super.initState();

    controller = Get.find<HomeProvider>();
  }

  // ------------------------------------------------------------
  // GREETING HELPERS
  // ------------------------------------------------------------

  String _greetingForNow() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    }

    return 'Good Evening';
  }

  String _greetingName() {
    final name =
        controller.loggedInUserName.value.trim();

    return name;
  }

  // ------------------------------------------------------------
  // LOGOUT CONFIRMATION
  // ------------------------------------------------------------

  void _showLogoutConfirmation() {
    if (_isExiting) {
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.lightBlue,
            ),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.find<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // OPEN LOAN DETAILS
  // ------------------------------------------------------------

  Future<void> _openLoanDetails({
    required Map<String, dynamic> loan,
    required int index,
  }) async {
    if (_isExiting) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isExiting = true;
      _selectedLoanIndex = index;
    });

    // ----------------------------------------------------------
    // Wait for the Home exit wave to complete.
    // ----------------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // Navigate only after Home has finished exiting.
    // ----------------------------------------------------------

    await Get.toNamed(
      AppRoutes.loanDashboard,
      arguments: loan,
    );

    if (!mounted) {
      return;
    }

    // Reset the exit state so the content slides back in
    // when the user returns from the loan details screen.
    setState(() {
      _isExiting = false;
      _selectedLoanIndex = null;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        showWatermark: true,
        showBottomImage: false,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshDashboard,
            color: AppColors.lightBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                24,
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // APPBAR-STYLE HEADER
                // LEFT: VSF Logo + "Home" | RIGHT: Notification + Logout
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: Duration.zero,
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.lightBlue.withValues(
                              alpha: 0.06,
                            ),
                            AppColors.primary.withValues(
                              alpha: 0.10,
                            ),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 16,
                            offset: const Offset(
                              0,
                              6,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            padding:
                                const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(
                                alpha: 0.85,
                              ),
                              border: Border.all(
                                color:
                                    Colors.white
                                        .withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 14,
                                  offset:
                                      const Offset(
                                        0,
                                        6,
                                      ),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/vsf.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  AppColors.lightBlue,
                            ),
                          ),

                          const Spacer(),

                          _HeaderIconButton(
                            tooltip: 'Notifications',
                            icon: Icons
                                .notifications_none_rounded,
                            iconSize: 22,
                            onPressed: () {
                              Get.toNamed(
                                AppRoutes
                                    .inAppNotifications,
                              );
                            },
                          ),

                          const SizedBox(width: 6),

                          _HeaderIconButton(
                            tooltip: 'Logout',
                            icon: Icons.logout_rounded,
                            iconSize: 20,
                            onPressed:
                                _showLogoutConfirmation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // GREETING CARD
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: Duration.zero,
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: Duration.zero,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.lightBlue
                                .withValues(alpha: 0.92),
                            AppColors.primary
                                .withValues(alpha: 0.82),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightBlue
                                .withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white
                                  .withValues(
                                alpha: 0.20,
                              ),
                            ),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(
                              () => Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    _greetingForNow(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _greetingName(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow
                                        .ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Here's a quick look at "
                                    'your loan overview.',
                                    style: TextStyle(
                                      color:
                                          Colors.white
                                              .withValues(
                                        alpha: 0.90,
                                      ),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // LOAN OVERVIEW
                // ENTRY LEFT - 80ms
                // EXIT RIGHT - 80ms
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(
                    milliseconds: 80,
                  ),
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: const Duration(
                      milliseconds: 80,
                    ),
                    child: const Text(
                      'Loan Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // SUMMARY CARDS
                // ENTRY LEFT - 160ms
                // EXIT RIGHT - 160ms
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(
                    milliseconds: 160,
                  ),
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: const Duration(
                      milliseconds: 160,
                    ),
                    child: Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: HomeSummaryCard(
                              title: 'Total',
                              value:
                                  controller.totalLoans.value,
                              icon: Icons
                                  .account_balance_wallet_outlined,
                              iconColor:
                                  AppColors.secondary,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: HomeSummaryCard(
                              title: 'Active',
                              value:
                                  controller.activeLoans.value,
                              icon: Icons
                                  .pending_actions_outlined,
                              iconColor:
                                  AppColors.buttonEnd,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: HomeSummaryCard(
                              title: 'Inactive',
                              value:
                                  controller.inactiveLoans.value,
                              icon: Icons
                                  .check_circle_outline,
                              iconColor:
                                  AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // MY LOANS HEADER
                // ENTRY LEFT - 240ms
                // EXIT RIGHT - 240ms
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(
                    milliseconds: 240,
                  ),
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: const Duration(
                      milliseconds: 240,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Loans',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      AppColors.lightBlue,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Track your vehicle loans',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Obx(
                          () => PopupMenuButton<String>(
                            initialValue: controller
                                .selectedFilter.value,
                            onSelected:
                                controller.setLoanFilter,
                            offset:
                                const Offset(0, 42),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                            itemBuilder: (context) =>
                                const [
                              PopupMenuItem<String>(
                                value: 'Total',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .all_inclusive_rounded,
                                      size: 18,
                                      color: AppColors
                                          .lightBlue,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Total Loans',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Active',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .pending_actions_outlined,
                                      size: 18,
                                      color: AppColors
                                          .buttonEnd,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Inactive',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .check_circle_outline,
                                      size: 18,
                                      color:
                                          AppColors.primary,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Inactive',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: AppColors.lightBlue
                                    .withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  100,
                                ),
                                border: Border.all(
                                  color:
                                      AppColors.lightBlue
                                          .withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .filter_list_rounded,
                                    size: 14,
                                    color: AppColors
                                        .lightBlue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    controller
                                        .selectedFilter
                                        .value,
                                    style:
                                        const TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: AppColors
                                          .lightBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons
                                        .keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors
                                        .lightBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LOANS
                // ==================================================

                Obx(() {
                  if (controller.isLoading.value) {
                    return ScreenContentExit(
                      isExiting: _isExiting,
                      direction:
                          ContentExitDirection.toRight,
                      delay: const Duration(
                        milliseconds: 320,
                      ),
                      child: ScreenContentTransition(
                        direction:
                            ContentTransitionDirection
                                .fromLeft,
                        delay: const Duration(
                          milliseconds: 320,
                        ),
                        child: const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(
                              vertical: 40,
                            ),
                            child:
                                CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller
                          .errorMessage.value !=
                      null) {
                    return ScreenContentExit(
                      isExiting: _isExiting,
                      direction:
                          ContentExitDirection.toRight,
                      delay: const Duration(
                        milliseconds: 320,
                      ),
                      child: ScreenContentTransition(
                        direction:
                            ContentTransitionDirection
                                .fromLeft,
                        delay: const Duration(
                          milliseconds: 320,
                        ),
                        child: Center(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 30,
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons
                                      .error_outline_rounded,
                                  size: 42,
                                  color:
                                      AppColors.error,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  controller
                                      .errorMessage.value!,
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    color:
                                        AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextButton(
                                  onPressed:
                                      controller.retry,
                                  child:
                                      const Text(
                                    'Try Again',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (controller
                      .filteredLoans.isEmpty) {
                    return ScreenContentExit(
                      isExiting: _isExiting,
                      direction:
                          ContentExitDirection.toRight,
                      delay: const Duration(
                        milliseconds: 320,
                      ),
                      child: ScreenContentTransition(
                        direction:
                            ContentTransitionDirection
                                .fromLeft,
                        delay: const Duration(
                          milliseconds: 320,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withValues(
                              alpha: 0.55,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            border: Border.all(
                              color:
                                  Colors.white.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .account_balance_wallet_outlined,
                                size: 42,
                                color: AppColors
                                    .secondary
                                    .withValues(
                                  alpha: 0.65,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                controller
                                            .selectedFilter
                                            .value ==
                                        'Total'
                                    ? 'No loans available'
                                    : 'No ${controller.selectedFilter.value.toLowerCase()} loans',
                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: AppColors
                                      .lightBlue,
                                ),
                                textAlign:
                                    TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                controller
                                            .selectedFilter
                                            .value ==
                                        'Total'
                                    ? 'Your loan information will appear here.'
                                    : 'There are no '
                                        '${controller.selectedFilter.value.toLowerCase()} '
                                        'loans at the moment.',
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black54,
                                ),
                                textAlign:
                                    TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: controller.filteredLoans
                        .asMap()
                        .entries
                        .map(
                      (entry) {
                        final index = entry.key;
                        final loan = entry.value;

                        // ------------------------------------------------
                        // Selected card exits first.
                        // Other cards follow behind it.
                        // ------------------------------------------------

                        final exitDelay =
                            _selectedLoanIndex == index
                                ? 0
                                : 80 +
                                    (index * 60);

                        return ScreenContentExit(
                          isExiting: _isExiting,
                          direction:
                              ContentExitDirection
                                  .toRight,
                          delay: Duration(
                            milliseconds: exitDelay,
                          ),
                          resetDelay: Duration(
                            milliseconds:
                                320 + (index * 80),
                          ),
                          child: ScreenContentTransition(
                            direction:
                                ContentTransitionDirection
                                    .fromLeft,
                            delay: Duration(
                              milliseconds:
                                  320 + (index * 80),
                            ),
                            child: HomeLoanCard(
                              loanNumber: loan['loanNumber']
                                      ?.toString() ??
                                  '',
                              borrowers: List<String>.from(
                                loan['borrowers'] as List? ??
                                    const <String>[],
                              ),
                              amount:
                                  (loan['amount'] as num)
                                      .toDouble(),
                              status:
                                  loan['status']?.toString() ??
                                      '',
                              onTap: () =>
                                  _openLoanDetails(
                                loan: loan,
                                index: index,
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  );
                }),

                // ==================================================
                // FOOTER
                // ENTRY LEFT - 420ms
                // EXIT RIGHT - 420ms
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(
                    milliseconds: 420,
                  ),
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: const Duration(
                      milliseconds: 420,
                    ),
                    child: const FooterVersion(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: AppColors.lightBlue.withValues(
                alpha: 0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: AppColors.lightBlue,
          ),
        ),
      ),
    );
  }
}