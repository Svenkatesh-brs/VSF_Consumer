import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/app_background.dart';
import '../widgets/app_form_card.dart';
import '../widgets/app_submit_button.dart';
import '../widgets/common/screen_content_exit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthProvider controller;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthProvider>();
  }

  // ------------------------------------------------------------
  // CONTINUE
  // ------------------------------------------------------------

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isExiting) {
      return;
    }

    if (!controller.validateMobileNumber()) {
      return;
    }

    setState(() {
      _isExiting = true;
    });

    // Wait for the complete staggered exit animation.
    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) {
      return;
    }

    Get.toNamed(AppRoutes.otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        showWatermark: false,
        showBottomImage: true,
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // ==================================================
                  // LOGO
                  // 0ms → RIGHT
                  // ==================================================

                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection.toRight,
                    duration: const Duration(milliseconds: 400),
                    delay: Duration.zero,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/vsf.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // ==================================================
                  // WELCOME TEXT
                  // 100ms → RIGHT
                  // ==================================================

                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection.toRight,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 80),
                    child: const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // DESCRIPTION
                  // 160ms → RIGHT
                  // ==================================================

                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection.toRight,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 140),
                    child: const Text(
                      'Access your vehicle loan information',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // LOGIN CARD
                  // 220ms → RIGHT
                  // ==================================================

                  ScreenContentExit(
                    isExiting: _isExiting,
                    direction: ContentExitDirection.toRight,
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: AppFormCard(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Obx(
                            () => TextField(
                              controller:
                                  controller.mobileController,
                              keyboardType:
                                  TextInputType.phone,
                              textInputAction:
                                  TextInputAction.done,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  10,
                                ),
                              ],
                              onChanged: (_) {
                                controller.clearError();
                              },
                              onSubmitted: (_) {
                                _continue();
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Enter 10-digit mobile number',
                                counterText: '',
                                prefixText: '+91 ',
                                errorText:
                                    controller.errorMessage.value,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Obx(
                            () => AppSubmitButton(
                              label: 'Continue',
                              isLoading:
                                  controller.isLoading.value ||
                                      _isExiting,
                              onTap: _isExiting
                                  ? null
                                  : _continue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}