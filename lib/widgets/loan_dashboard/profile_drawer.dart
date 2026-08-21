import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';

class ProfileDrawer extends StatelessWidget {
  final String avatarAsset;

  const ProfileDrawer({
    super.key,
    this.avatarAsset = 'assets/vsf.png',
  });

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
        return ProfileDrawer(
          avatarAsset: avatarAsset,
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        28,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.96,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
                borderRadius: BorderRadius.circular(
                  100,
                ),
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
                    color: AppColors.lightBlue
                        .withValues(
                      alpha: 0.08,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatarAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              AppColors.lightBlue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Manage your account',
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
              ],
            ),

            const SizedBox(height: 22),

            _buildDrawerItem(
              icon: Icons.person_outline_rounded,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);

                Get.snackbar(
                  'My Profile',
                  'Profile will be available soon.',
                  snackPosition:
                      SnackPosition.BOTTOM,
                  margin:
                      const EdgeInsets.all(16),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);

                Get.snackbar(
                  'Help & Support',
                  'Support will be available soon.',
                  snackPosition:
                      SnackPosition.BOTTOM,
                  margin:
                      const EdgeInsets.all(16),
                );
              },
            ),

            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);

                Get.snackbar(
                  'Logout',
                  'Logout will be implemented later.',
                  snackPosition:
                      SnackPosition.BOTTOM,
                  margin:
                      const EdgeInsets.all(16),
                );
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
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 4,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(
                  alpha: 0.07,
                ),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: AppColors.lightBlue,
              ),
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
