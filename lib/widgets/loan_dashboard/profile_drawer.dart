import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_selection_provider.dart';
import '../../models/language_selection_model.dart';
import '../../utils/app_colors.dart';

class ProfileDrawer extends StatelessWidget {
  final String avatarAsset;

  const ProfileDrawer({super.key, this.avatarAsset = 'assets/vsf.png'});

  // ============================================================
  // SHOW
  // ============================================================

  static Future<void> show(
    BuildContext context, {
    String avatarAsset = 'assets/vsf.png',
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ProfileDrawer(avatarAsset: avatarAsset);
      },
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final languageProvider = Get.find<LanguageSelectionProvider>();
    var selectedCode = Get.locale?.languageCode ?? languageProvider.languageCode;
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
                children: LanguageSelectionModel.supportedLanguages.map(
                  (language) {
                    final isSelected = language.languageCode == selectedCode;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.buttonEnd
                            : Colors.black26,
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
                  },
                ).toList(),
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
                            Get.snackbar(
                              'language'.tr,
                              'language_updated'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                          } catch (_) {
                            if (!dialogContext.mounted) return;

                            setState(() => isSaving = false);
                            Get.snackbar(
                              'error'.tr,
                              'unable_save_language'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
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

                Get.snackbar(
                  'my_profile'.tr,
                  'profile_coming_soon'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              title: 'help_support'.tr,
              onTap: () {
                Navigator.pop(context);

                Get.snackbar(
                  'help_support'.tr,
                  'support_coming_soon'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.language_rounded,
              title: 'language'.tr,
              onTap: () => _showLanguagePicker(context),
            ),

            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'logout'.tr,
              onTap: () async {
                Navigator.pop(context);

                final authProvider = Get.find<AuthProvider>();

                await authProvider.logout();
              },
            ),
          ],
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
