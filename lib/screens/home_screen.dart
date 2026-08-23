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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                // HEADER
                // ENTRY LEFT
                // EXIT RIGHT
                // ==================================================

                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: Duration.zero,
                  child: ScreenContentTransition(
                    direction:
                        ContentTransitionDirection.fromLeft,
                    delay: Duration.zero,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  'Good Morning 👋, '
                                  '${controller.loggedInUserName.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w500,
                                    color:
                                        Colors.black.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.lightBlue,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Here is your loan overview',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.black.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Logout',
                              onPressed:
                                  _showLogoutConfirmation,
                              icon: Container(
                                width: 40,
                                height: 40,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.75,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 12,
                                      offset:
                                          const Offset(
                                        0,
                                        5,
                                      ),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  size: 19,
                                  color:
                                      AppColors.lightBlue,
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            Container(
                              width: 52,
                              height: 52,
                              padding:
                                  const EdgeInsets.all(5),
                              decoration:
                                  BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.white.withValues(
                                  alpha: 0.75,
                                ),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

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
    );
  }
}