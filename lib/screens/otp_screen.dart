import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/app_background.dart';
import '../widgets/app_form_card.dart';
import '../widgets/app_submit_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  late final AuthProvider controller;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  final FocusNode _otpFocusNode = FocusNode();

  bool _verificationSuccessful = false;

  late final AnimationController _successController;

  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  @override
  void initState() {
    super.initState();

    controller = Get.find<AuthProvider>();

    controller.startOtpTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    _otpFocusNode.addListener(() {
      setState(() {});
    });

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );
  }

  void _verifyOtp() {
    FocusManager.instance.primaryFocus?.unfocus();

    final isValid = controller.validateOtp();

    if (isValid) {
      setState(() {
        _verificationSuccessful = true;
      });

      _successController
        ..reset()
        ..forward();

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;

        Get.offNamed(AppRoutes.home);
      });

      return;
    }

    _shakeController
      ..reset()
      ..forward();
  }

  void _focusOtpField() {
    FocusScope.of(context).requestFocus(_otpFocusNode);
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.back();
  }

  void _resendOtp() {
    FocusManager.instance.primaryFocus?.unfocus();
    controller.resendOtp();
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Widget _buildOtpBoxes({required bool hasError}) {
    final otp = controller.otpController.text;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        children: List.generate(6, (index) {
          final hasValue = index < otp.length;

          final isFocused =
              _otpFocusNode.hasFocus && index == otp.length && otp.length < 6;

          Color borderColor;

          if (hasError) {
            borderColor = Colors.red;
          } else if (isFocused) {
            borderColor = Colors.blue;
          } else {
            borderColor = Colors.black.withValues(alpha: 0.18);
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 5 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasError
                      ? Colors.red.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: hasError || isFocused ? 1.8 : 1,
                  ),
                ),
                child: Text(
                  hasValue ? otp[index] : '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobileNumber = controller.mobileController.text.trim();

    final maskedMobile = mobileNumber.length == 10
        ? '${mobileNumber.substring(0, 2)}******${mobileNumber.substring(8)}'
        : mobileNumber;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        showWatermark: false,
        showBottomImage: true,
        child: SafeArea(
          child: Stack(
            children: [
              // ============================================================
              // MAIN OTP SCREEN
              // ============================================================
              GestureDetector(
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

                      // ------------------------------------------------
                      // BACK BUTTON
                      // ------------------------------------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ------------------------------------------------
                      // VSF LOGO
                      // ------------------------------------------------
                      Center(
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

                      const SizedBox(height: 45),

                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------
                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // ------------------------------------------------
                      // DESCRIPTION
                      // ------------------------------------------------
                      Text(
                        maskedMobile.isEmpty
                            ? 'Enter the 6-digit OTP to continue'
                            : 'Enter the 6-digit OTP sent to +91 $maskedMobile',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // OTP FORM CARD
                      // ==================================================
                      AppFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OTP',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ------------------------------------------------
                            // OTP INPUT
                            // ------------------------------------------------
                            Stack(
                              children: [
                                // Visual OTP boxes
                                Obx(
                                  () => GestureDetector(
                                    onTap: _focusOtpField,
                                    behavior: HitTestBehavior.opaque,
                                    child: _buildOtpBoxes(
                                      hasError:
                                          controller.errorMessage.value != null,
                                    ),
                                  ),
                                ),

                                // Real input field
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.01,
                                    child: TextField(
                                      controller: controller.otpController,
                                      focusNode: _otpFocusNode,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.done,
                                      maxLength: 6,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      onChanged: (_) {
                                        setState(() {});
                                        controller.clearError();
                                      },
                                      onSubmitted: (_) {
                                        _verifyOtp();
                                      },
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ------------------------------------------------
                            // ERROR MESSAGE
                            // ------------------------------------------------
                            Obx(() {
                              final error = controller.errorMessage.value;

                              if (error == null || error.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 20),

                            // ------------------------------------------------
                            // VERIFY BUTTON
                            // ------------------------------------------------
                            Obx(
                              () => AppSubmitButton(
                                label: 'Verify',
                                isLoading: controller.isLoading.value,
                                onTap: _verificationSuccessful
                                    ? null
                                    : _verifyOtp,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ------------------------------------------------
                            // RESEND OTP
                            // ------------------------------------------------
                            Obx(() {
                              final countdown = controller.otpCountdown.value;

                              final canResend = controller.canResendOtp.value;

                              return Center(
                                child: canResend
                                    ? TextButton(
                                        onPressed: _resendOtp,
                                        child: const Text('Resend OTP'),
                                      )
                                    : Text(
                                        'Resend OTP in ${countdown}s',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ============================================================
              // SCREEN-LEVEL SUCCESS OVERLAY
              // ============================================================
              if (_verificationSuccessful)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: FadeTransition(
                        opacity: _successFade,
                        child: ScaleTransition(
                          scale: _successScale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                const Text(
                                  'Verification successful',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
