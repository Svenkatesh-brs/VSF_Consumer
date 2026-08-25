import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/notification_service.dart';
import '../models/request_otp_model.dart';
import '../models/verify_otp_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends GetxController {
  final AuthService _authService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  AuthProvider({
    required AuthService authService,
    required StorageService storageService,
    required NotificationService notificationService,
  }) : _authService = authService,
       _storageService = storageService,
       _notificationService = notificationService;

  @override
  void onInit() {
    super.onInit();

    _notificationService.initializeNotifications();
  }

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController mobileController = TextEditingController();

  final TextEditingController otpController = TextEditingController();

  // ============================================================
  // REACTIVE STATE
  // ============================================================

  final RxBool isLoading = false.obs;

  final RxnString errorMessage = RxnString();

  final RxInt otpCountdown = 30.obs;

  final RxBool canResendOtp = false.obs;

  // ============================================================
  // OTP RESPONSE
  // ============================================================

  VerifyOtpResponse? _verifyOtpResponse;

  VerifyOtpResponse? get verifyOtpResponse => _verifyOtpResponse;

  // ============================================================
  // OTP TIMER
  // ============================================================

  Timer? _otpTimer;

  void startOtpTimer() {
    _otpTimer?.cancel();

    otpCountdown.value = 30;
    canResendOtp.value = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown.value > 0) {
        otpCountdown.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  // ============================================================
  // MOBILE NUMBER VALIDATION
  // ============================================================

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
      errorMessage.value = 'Please enter a valid mobile number.';
      return false;
    }

    errorMessage.value = null;

    return true;
  }

  // ============================================================
  // OTP VALIDATION
  // ============================================================

  bool validateOtp() {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      errorMessage.value = 'Please enter the OTP.';
      return false;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      errorMessage.value = 'Please enter the 6-digit OTP.';
      return false;
    }

    errorMessage.value = null;

    return true;
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    errorMessage.value = null;
  }

  // ============================================================
  // REQUEST OTP
  // ============================================================

  Future<bool> requestOtp({
    required String countryCode,
    required String phone,
  }) async {
    if (isLoading.value) {
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final request = RequestOtpRequest(countryCode: countryCode, phone: phone);

      final response = await _authService.requestOtp(request);

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.success) {
        isLoading.value = false;

        startOtpTimer();

        return true;
      }

      // --------------------------------------------------------
      // API FAILURE
      // --------------------------------------------------------

      errorMessage.value = _getRequestOtpErrorMessage(response.message);

      isLoading.value = false;

      return false;
    } catch (e) {
      errorMessage.value = _getApiErrorMessage(
        e,
        defaultMessage: 'Unable to send OTP. Please try again.',
      );

      isLoading.value = false;

      return false;
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<bool> resendOtp() async {
    if (!canResendOtp.value || isLoading.value) {
      return false;
    }

    clearError();

    final phone = mobileController.text.trim();

    if (phone.isEmpty) {
      errorMessage.value = 'Mobile number is required.';
      return false;
    }

    final success = await requestOtp(countryCode: '+91', phone: phone);

    if (success) {
      otpController.clear();
    }

    return success;
  }

  // ============================================================
  // VERIFY OTP API
  // ============================================================

  Future<bool> verifyOtp({
    required String countryCode,
    required String phone,
    required String otp,
  }) async {
    if (isLoading.value) {
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final request = VerifyOtpRequest(
        countryCode: countryCode,
        phone: phone,
        otp: otp,
      );

      final response = await _authService.verifyOtp(request);

      _verifyOtpResponse = response;

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.success &&
          response.token != null &&
          response.token!.isNotEmpty) {
        await _storageService.saveToken(response.token!);

        // Register this device for push notifications.
        // Notification registration failure should not prevent login.
        try {
          await _notificationService.requestNotificationPermission();
          await _notificationService.registerDevice();
        } catch (_) {
          // Ignore notification errors.
          // The user can still continue using the application.
        }

        isLoading.value = false;

        return true;
      }

      // --------------------------------------------------------
      // API FAILURE
      // --------------------------------------------------------

      errorMessage.value = _getOtpErrorMessage(response.message);

      isLoading.value = false;

      return false;
    } catch (e) {
      errorMessage.value = _getApiErrorMessage(
        e,
        defaultMessage: 'Unable to verify OTP. Please try again.',
      );

      isLoading.value = false;

      return false;
    }
  }

  // ============================================================
  // REQUEST OTP ERROR
  // ============================================================

  String _getRequestOtpErrorMessage(String message) {
    if (message.trim().isEmpty) {
      return 'Unable to send OTP. Please try again.';
    }

    return message;
  }

  // ============================================================
  // OTP RESPONSE ERROR
  // ============================================================

  String _getOtpErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid') && lowerMessage.contains('otp')) {
      return 'Invalid or expired OTP';
    }

    if (lowerMessage.contains('expired')) {
      return 'Invalid or expired OTP';
    }

    if (message.trim().isEmpty) {
      return 'OTP verification failed.';
    }

    return message;
  }

  // ============================================================
  // GENERAL API ERROR
  // ============================================================

  String _getApiErrorMessage(Object error, {required String defaultMessage}) {
    final message = error.toString().toLowerCase();

    if (message.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (message.contains('connect')) {
      return 'Unable to connect to the server.';
    }

    if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return defaultMessage;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _storageService.removeToken();

      // Clear authentication state.
      _verifyOtpResponse = null;

      // Clear errors.
      errorMessage.value = null;

      // Clear input fields.
      mobileController.clear();
      otpController.clear();

      // Stop OTP timer.
      _otpTimer?.cancel();

      otpCountdown.value = 30;
      canResendOtp.value = false;

      // Reset loading state.
      isLoading.value = false;

      // Go back to login and remove previous routes.
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      errorMessage.value = 'Unable to logout. Please try again.';
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    _otpTimer?.cancel();

    mobileController.dispose();
    otpController.dispose();

    super.onClose();
  }
}
