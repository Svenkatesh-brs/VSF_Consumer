import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/language_selection_provider.dart';
import '../../providers/loan_dashboard_provider.dart';
import '../../models/language_selection_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import 'loan_picker_dialog.dart';


class ProfileDrawer extends StatelessWidget {
  final String avatarAsset;
  final VoidCallback? onLanguageChanged;

  const ProfileDrawer({
    super.key,
    this.avatarAsset = 'assets/vsf.png',
    this.onLanguageChanged,
  });

  static void _showStyledSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      duration: const Duration(seconds: 2),
      icon: Icon(icon, color: Colors.white),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 250),
    );
  }

  // ============================================================
  // SHOW
  // ============================================================

  static Future<void> show(
    BuildContext context, {
    String avatarAsset = 'assets/vsf.png',
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ProfileDrawer(
          avatarAsset: avatarAsset,
          onLanguageChanged: () {
            _showStyledSnackbar(
              title: 'language'.tr,
              message: 'language_updated'.tr,
              backgroundColor: Colors.green.shade700,
              icon: Icons.check_circle_rounded,
            );
          },
        );
      },
    );

    Get.closeCurrentSnackbar();
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final languageProvider = Get.find<LanguageSelectionProvider>();
    var selectedCode =
        Get.locale?.languageCode ?? languageProvider.languageCode;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text('select_language'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: LanguageSelectionModel.supportedLanguages.map((
                  language,
                ) {
                  final isSelected = language.languageCode == selectedCode;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.buttonEnd : Colors.black26,
                    ),
                    title: Text(_languageLabel(language.languageCode)),
                    subtitle: Text(language.nativeName),
                    onTap: isSaving
                        ? null
                        : () {
                            setState(
                              () => selectedCode = language.languageCode,
                            );
                          },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);

                          try {
                            await languageProvider.changeLanguage(selectedCode);

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            onLanguageChanged?.call();
                          } catch (_) {
                            if (!dialogContext.mounted) return;

                            setState(() => isSaving = false);
                            _showStyledSnackbar(
                              title: 'error'.tr,
                              message: 'unable_save_language'.tr,
                              backgroundColor: Colors.red.shade700,
                              icon: Icons.error_rounded,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'te':
        return 'telugu'.tr;
      case 'hi':
        return 'hindi'.tr;
      case 'en':
      default:
        return 'english'.tr;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    // Close the profile sheet first, then present the same confirmation used
    // by the Home-screen logout control.
    Navigator.pop(context);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.lightBlue),
            const SizedBox(width: 10),
            Text(
              'logout_confirmation_title'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.lightBlue,
              ),
            ),
          ],
        ),
        content: Text(
          'logout_confirmation_message'.tr,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.black54)),
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
            child: Text(
              'logout'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED LOAN PROVIDER
  //
  // The drawer is opened from Home and from the Loan Dashboard. In
  // both cases LoanDashboardProvider is already registered (Home via
  // HomeBinding, the dashboard via LoanDashboardBinding) and it is
  // the app's single owner of the selected loan, so no extra
  // loan-management state is introduced here.
  // ============================================================

  LoanDashboardProvider? get _loanProvider {
    if (!Get.isRegistered<LoanDashboardProvider>()) {
      return null;
    }

    return Get.find<LoanDashboardProvider>();
  }

  // ============================================================
  // LOAN PICKER
  //
  // Opens the compact picker over the drawer and, once a loan is
  // chosen, loads it through LoanDashboardProvider.selectLoan so the
  // EMI schedule, transactions and contact details shown afterwards
  // belong to exactly that loan.
  //
  // Returns true when a loan is ready to use.
  // ============================================================

  Future<bool> _showLoanPicker(BuildContext context) async {
    final loanProvider = _loanProvider;

    if (loanProvider == null) {
      _showStyledSnackbar(
        title: 'error'.tr,
        message: 'error_unable_load'.tr,
        backgroundColor: Colors.red.shade700,
        icon: Icons.error_rounded,
      );

      return false;
    }

    // "My Loans" is already in memory from Home; the picker only
    // reads it, so opening it never triggers an extra request.
    final homeProvider = Get.isRegistered<HomeProvider>()
        ? Get.find<HomeProvider>()
        : null;

    final picked = await LoanPickerDialog.show(
      context,
      loans: homeProvider?.loans ?? const <Map<String, dynamic>>[],
      selectedLoanNumber: loanProvider.loanNumber,
      isLoading: homeProvider?.isLoading.value ?? false,
    );

    if (picked == null) {
      return false;
    }

    final loaded = await loanProvider.selectLoan(picked);

    if (!loaded) {
      _showStyledSnackbar(
        title: 'error'.tr,
        message: loanProvider.errorMessage.value ?? 'error_unable_load'.tr,
        backgroundColor: Colors.red.shade700,
        icon: Icons.error_rounded,
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightBlue.withValues(alpha: 0.08),
                  ),
                  child: ClipOval(
                    child: Image.asset(avatarAsset, fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'manage_account'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'manage_account_description'.tr,
                        style: TextStyle(
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

            const SizedBox(height: 22),

            _buildDrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'my_profile'.tr,
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.profile);
              },
            ),

            // ------------------------------------------------------------
            // QUICK ACTIONS
            //
            // Wrapped in Obx so the selected-loan chip reacts to the
            // shared LoanDashboardProvider state on both entry points:
            // empty on Home, already filled on the Loan Dashboard.
            // ------------------------------------------------------------

            if (_loanProvider case final loanProvider?)
              Obx(
                () => _QuickActionsDropdown(
                  selectedLoanNumber: loanProvider.loanNumber,
                  isSelectingLoan: loanProvider.isLoading.value,
                  onNavigate: (route) {
                    Navigator.pop(context);
                    Get.toNamed(route);
                  },
                  onRequestLoan: _showLoanPicker,
                ),
              ),


            _buildDrawerItem(
              icon: Icons.language_rounded,
              title: 'language'.tr,
              onTap: () => _showLanguagePicker(context),
            ),

            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'logout'.tr,
              onTap: () => _showLogoutConfirmation(context),
            ),
              ],
            ),
          ),
        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 21, color: AppColors.lightBlue),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
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
    );
  }
}

// ============================================================
// QUICK ACTIONS
//
// The same section is used from Home and from the Loan Dashboard;
// the entry point is what makes it behave differently, and that
// difference is expressed entirely through the shared selected-loan
// state (see LoanDashboardProvider):
//
//   * Loan Dashboard -> a loan is already selected, so the chip is
//     filled in and every action runs on that loan immediately.
//   * Home           -> no loan is selected, so the label is plain
//     and the first loan-specific tap opens the loan picker.
//
// There is deliberately no "opened from" flag: the drawer reads the
// one selected loan that the whole loan feature already uses.
// ============================================================

class _QuickActionsDropdown extends StatelessWidget {
  final String selectedLoanNumber;

  final bool isSelectingLoan;

  final ValueChanged<String> onNavigate;

  final Future<bool> Function(BuildContext) onRequestLoan;

  const _QuickActionsDropdown({
    required this.selectedLoanNumber,
    required this.isSelectingLoan,
    required this.onNavigate,
    required this.onRequestLoan,
  });

  // ============================================================
  // LOAN-SPECIFIC ACTIONS
  //
  // These read loan data from LoanDashboardProvider, so a loan must
  // be selected before they can open. Help & Support is purely
  // informational and always opens directly.
  // ============================================================

  static const Set<String> _loanSpecificRoutes = <String>{
    AppRoutes.emiSchedule,
    AppRoutes.transactions,
    AppRoutes.contactUpdate,
    AppRoutes.complaint,
  };

  Future<void> _handleTap(BuildContext context, String route) async {
    if (_loanSpecificRoutes.contains(route) &&
        selectedLoanNumber.isEmpty) {
      // Home: no loan yet — ask for one first, then continue to the
      // action the customer originally tapped.
      final hasLoan = await onRequestLoan(context);

      if (!hasLoan) {
        return;
      }
    }

    onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(left: 18, bottom: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.bolt_outlined,
            size: 21,
            color: AppColors.lightBlue,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                'quick_actions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightBlue,
                ),
              ),
            ),

            if (isSelectingLoan) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lightBlue,
                ),
              ),
            ] else if (selectedLoanNumber.isNotEmpty) ...[
              const SizedBox(width: 8),
              _LoanNumberChip(
                loanNumber: selectedLoanNumber,
                onTap: () => onRequestLoan(context),
              ),
            ],
          ],
        ),
        iconColor: AppColors.lightBlue,
        collapsedIconColor: Colors.black26,
        children: [
          _QuickActionItem(
            icon: Icons.event_note_outlined,
            title: 'emi_schedule'.tr,
            onTap: () => _handleTap(context, AppRoutes.emiSchedule),
          ),
          _QuickActionItem(
            icon: Icons.swap_vert_rounded,
            title: 'transactions'.tr,
            onTap: () => _handleTap(context, AppRoutes.transactions),
          ),
          _QuickActionItem(
            icon: Icons.contact_phone_outlined,
            title: 'contact_update'.tr,
            onTap: () => _handleTap(context, AppRoutes.contactUpdate),
          ),
          _QuickActionItem(
            icon: Icons.report_problem_outlined,
            title: 'complaints'.tr,
            onTap: () => _handleTap(context, AppRoutes.complaint),
          ),
          _QuickActionItem(
            icon: Icons.help_outline_rounded,
            title: 'help'.tr,
            onTap: () => _handleTap(context, AppRoutes.help),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOAN NUMBER CHIP
//
// Rendered next to the Quick Actions label as
// "Quick Actions • LN123456". Tapping it reopens the loan picker so
// the customer can switch to another loan.
//
// The number is Flexible with a single ellipsised line so the row
// never overflows on small devices or with long loan numbers.
// ============================================================

class _LoanNumberChip extends StatelessWidget {
  final String loanNumber;

  final VoidCallback onTap;

  const _LoanNumberChip({required this.loanNumber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.lightBlue.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    loanNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 12,
                  color: AppColors.lightBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, size: 20, color: AppColors.lightBlue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.black26,
      ),
      onTap: onTap,
    );
  }
}
