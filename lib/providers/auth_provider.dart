import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

import 'dart:async';

class AuthProvider extends GetxController {
  Timer? _otpTimer;

  final otpCountdown = 30.obs;

  final canResendOtp = false.obs;
  void startOtpTimer() {
    _otpTimer?.cancel();

    otpCountdown.value = 30;
    canResendOtp.value = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown.value > 0) {
        otpCountdown.value--;
      }

      if (otpCountdown.value == 0) {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  void resendOtp() {
    if (!canResendOtp.value) {
      return;
    }

    clearError();

    // Static version:
    // No API call is made.
    // Simply restart the countdown.
    startOtpTimer();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  final mobileController = TextEditingController();

  // ------------------------------------------------------------
  // OTP
  // ------------------------------------------------------------

  final otpController = TextEditingController();

  // ------------------------------------------------------------
  // COMMON STATE
  // ------------------------------------------------------------

  final isLoading = false.obs;
  final errorMessage = RxnString();

  // ------------------------------------------------------------
  // LOGIN VALIDATION
  // ------------------------------------------------------------

  bool validateMobileNumber() {
    final mobileNumber = mobileController.text.trim();

    if (mobileNumber.isEmpty) {
      errorMessage.value = 'Please enter your mobile number.';
      return false;
    }

    if (mobileNumber.length != 10) {
      errorMessage.value = 'Please enter a valid 10-digit mobile number.';
      return false;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
      errorMessage.value = 'Please enter a valid 10-digit mobile number.';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  // ------------------------------------------------------------
  // OTP VALIDATION
  // ------------------------------------------------------------

  bool validateOtp() {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      errorMessage.value = 'Please enter the OTP.';
      return false;
    }

    if (otp.length != 6) {
      errorMessage.value = 'Please enter a valid 6-digit OTP.';
      return false;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      errorMessage.value = 'Please enter a valid 6-digit OTP.';
      return false;
    }

    // Static/demo OTP.
    if (otp != '123456') {
      errorMessage.value = 'Invalid OTP. Please try again.';
      return false;
    }

    errorMessage.value = null;
    return true;
  }

  // ------------------------------------------------------------
  // CLEAR ERROR
  // ------------------------------------------------------------

  void clearError() {
    errorMessage.value = null;
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  void logout() {
  clearError();

  _otpTimer?.cancel();

  // Destroy this AuthProvider instance explicitly (permanent providers are
  // never removed by route disposal). The next login flow then creates a
  // fresh instance with new controllers. Doing this BEFORE navigating means
  // no screen can ever grab a reference to a disposed provider.
  Get.delete<AuthProvider>(force: true);

  Get.offAllNamed(AppRoutes.login);
}

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void onClose() {
    _otpTimer?.cancel();
    mobileController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
