import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/app_background.dart';
import '../widgets/common/screen_content_exit.dart';
import '../widgets/common/screen_transition.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _isExiting = false;

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
  // SUPPORT MESSAGE
  //
  // Uses the same snackbar style as the Loan Dashboard.
  // ============================================================

  void _showSupportMessage(String title, String message) {
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
  // URL LAUNCHING
  //
  // Every failure path (nothing registered for the URL, the
  // launcher returning false, or an exception such as a missing
  // WhatsApp install) degrades into a friendly snackbar instead
  // of crashing the screen.
  // ============================================================

  Future<void> _launchUrl(
    Uri uri, {
    required String failureTitle,
    required String failureMessage,
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final bool launched = await launchUrl(uri, mode: mode);

      if (!launched && mounted) {
        _showSupportMessage(failureTitle, failureMessage);
      }
    } catch (_) {
      if (mounted) {
        _showSupportMessage(failureTitle, failureMessage);
      }
    }
  }

  // ============================================================
  // CALL SUPPORT
  // ============================================================

  Future<void> _callSupport() {
    return _launchUrl(
      Uri(scheme: 'tel', path: AppConstants.supportPhone),
      failureTitle: 'call_support'.tr,
      failureMessage: 'calling_unavailable'.tr,
    );
  }

  // ============================================================
  // WHATSAPP SUPPORT
  // ============================================================

  Future<void> _openWhatsAppSupport() {
    return _launchUrl(
      Uri.parse('https://wa.me/${AppConstants.supportPhoneIntl}'),
      mode: LaunchMode.externalApplication,
      failureTitle: 'whatsapp_support'.tr,
      failureMessage: 'whatsapp_unavailable'.tr,
    );
  }

  // ============================================================
  // HELP TOPICS
  //
  // Informational only - they point the customer back to the
  // live contact channels above. No API calls are made.
  // ============================================================

  void _onHelpTopicTap(String topic) {
    _showSupportMessage(
      topic,
      'support_topic_message'.trParams({'topic': topic}),
    );
  }

  // ============================================================
  // HERO SUPPORT CARD
  // ============================================================

  Widget _buildHeroCard() {
    final coverageChips = <String>[
      'loans_emi'.tr,
      'payments'.tr,
      'account'.tr,
      'complaints'.tr,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.80),
            Colors.white.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.buttonEnd.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 29,
                  color: AppColors.lightBlue,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'need_assistance'.tr,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightBlue,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'support_description'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            height: 1,
            color: AppColors.lightBlue.withValues(alpha: 0.07),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: coverageChips
                .map(
                  (chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.lightBlue.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION LABEL
  // ============================================================

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: Colors.black45,
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT OPTION CARD
  //
  // Large tappable card used for both Call and WhatsApp.
  // ============================================================

  Widget _buildContactOption({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String number,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.80),
                  Colors.white.withValues(alpha: 0.48),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.60),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.14),
                        accentColor.withValues(alpha: 0.07),
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, size: 23, color: accentColor),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        number,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.lightBlue,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
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
  // CONTACT OPTIONS
  // ============================================================

  List<Widget> _buildContactOptions() {
    return [
      _buildContactOption(
        icon: Icons.phone_outlined,
        accentColor: const Color(0xFF268B68),
        title: 'call_support'.tr,
        number: AppConstants.supportPhone,
        subtitle: 'speak_support_team'.tr,
        onTap: _callSupport,
      ),

      _buildContactOption(
        icon: Icons.chat_bubble_outline_rounded,
        accentColor: const Color(0xFF258F92),
        title: 'whatsapp_support'.tr,
        number: AppConstants.supportPhone,
        subtitle: 'chat_support_team'.tr,
        onTap: _openWhatsAppSupport,
      ),
    ];
  }

  // ============================================================
  // HELP TOPIC CARD
  //
  // Static informational card reusing the dashboard's feature
  // icons and accent colors.
  // ============================================================

  Widget _buildHelpTopicCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _onHelpTopicTap(title);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.44),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.14),
                        accentColor.withValues(alpha: 0.07),
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightBlue,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
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
  // HELP TOPICS
  // ============================================================

  List<Widget> _buildHelpTopics() {
    return [
      _buildHelpTopicCard(
        icon: Icons.event_note_outlined,
        accentColor: const Color(0xFF258F92),
        title: 'loans_emi'.tr,
        description: 'loan_emi_help'.tr,
      ),

      _buildHelpTopicCard(
        icon: Icons.receipt_long_outlined,
        accentColor: const Color(0xFF5968BE),
        title: 'payments_receipts'.tr,
        description: 'payment_status_history_receipts'.tr,
      ),

      _buildHelpTopicCard(
        icon: Icons.contact_phone_outlined,
        accentColor: const Color(0xFF6956C8),
        title: 'account_contact_details'.tr,
        description: 'profile_contact_updates'.tr,
      ),

      _buildHelpTopicCard(
        icon: Icons.report_problem_outlined,
        accentColor: const Color(0xFFD8893F),
        title: 'complaints'.tr,
        description: 'raise_follow_issue'.tr,
      ),
    ];
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================================================
                // HEADER
                // ENTRY LEFT - 0ms
                // EXIT RIGHT - 0ms
                // ================================================

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

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'help_support'.tr,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lightBlue,
                                ),
                              ),

                              SizedBox(height: 2),

                              Text(
                                'were_here_to_help'.tr,
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
                  ),
                ),

                const SizedBox(height: 24),

                // ================================================
                // HERO SUPPORT CARD
                // ENTRY LEFT - 80ms
                // EXIT RIGHT - 80ms
                // ================================================
                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(milliseconds: 80),
                  child: ScreenContentTransition(
                    direction: ContentTransitionDirection.fromLeft,
                    delay: const Duration(milliseconds: 80),
                    child: _buildHeroCard(),
                  ),
                ),

                const SizedBox(height: 24),

                // ================================================
                // CONTACT OPTIONS
                // ENTRY LEFT - 160ms
                // EXIT RIGHT - 160ms
                // ================================================
                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(milliseconds: 160),
                  child: ScreenContentTransition(
                    direction: ContentTransitionDirection.fromLeft,
                    delay: const Duration(milliseconds: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('contact_us'.tr),

                        ..._buildContactOptions(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ================================================
                // HELP TOPICS
                // ENTRY LEFT - 240ms
                // EXIT RIGHT - 240ms
                // ================================================
                ScreenContentExit(
                  isExiting: _isExiting,
                  direction: ContentExitDirection.toRight,
                  delay: const Duration(milliseconds: 240),
                  child: ScreenContentTransition(
                    direction: ContentTransitionDirection.fromLeft,
                    delay: const Duration(milliseconds: 240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('how_can_we_help'.tr),

                        ..._buildHelpTopics(),
                      ],
                    ),
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
