import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/notification_service.dart';
import '../models/request_otp_model.dart';
import '../models/verify_otp_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/otp_autofill_service.dart';

class AuthProvider extends GetxController {
  final AuthService _authService;
  final StorageService _storageService;
  final NotificationService _notificationService;
  final OtpAutofillService _otpAutofillService;

  AuthProvider({
    required AuthService authService,
    required StorageService storageService,
    required NotificationService notificationService,
    required OtpAutofillService otpAutofillService,
  }) : _authService = authService,
       _storageService = storageService,
       _notificationService = notificationService,
       _otpAutofillService = otpAutofillService;

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

  final RxString otpValue = ''.obs;

  /// Increments only when SMS Retriever supplies a valid code. This lets the
  /// screen distinguish an autofill event from manual TextField entry.
  final RxInt otpAutofillRevision = 0.obs;

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
  StreamSubscription<String>? _otpAutofillSubscription;

  void setOtp(String value) {
    otpController.value = otpController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    otpValue.value = value;
  }

  void updateOtpFromInput(String value) {
    otpValue.value = value;
  }

  Future<void> prepareOtpAutofill() async {
    await _otpAutofillSubscription?.cancel();
    _otpAutofillSubscription = _otpAutofillService.codes.listen((code) {
      if (RegExp(r'^\d{6}$').hasMatch(code)) {
        setOtp(code);
        clearError();
        otpAutofillRevision.value++;
      }
    });
    await _otpAutofillService.arm();
  }

  Future<void> stopOtpAutofill() async {
    await _otpAutofillSubscription?.cancel();
    _otpAutofillSubscription = null;
    await _otpAutofillService.disarm();
  }

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

    setOtp('');
    otpAutofillRevision.value = 0;
    try {
      await prepareOtpAutofill();
    } catch (_) {
      // SMS Retriever is an optional convenience; do not block manual OTP.
    }

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

      await stopOtpAutofill();

      isLoading.value = false;

      return false;
    } catch (e) {
      errorMessage.value = _getApiErrorMessage(
        e,
        defaultMessage: 'Unable to send OTP. Please try again.',
      );

      isLoading.value = false;

      await stopOtpAutofill();

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

    return requestOtp(countryCode: '+91', phone: phone);
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
      setOtp('');

      await stopOtpAutofill();

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
    _otpAutofillSubscription?.cancel();
    unawaited(_otpAutofillService.dispose());

    mobileController.dispose();
    otpController.dispose();

    super.onClose();
  }
}
