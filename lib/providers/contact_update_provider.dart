import 'dart:async';

import 'package:get/get.dart';

import '../models/contact_update_model.dart';
import '../models/loan_details_model.dart';
import '../models/request_otp_model.dart';
import '../models/verify_otp_model.dart';
import '../services/contact_update_service.dart';
import 'loan_dashboard_provider.dart';

// ============================================================
// CONTACT UPDATE PROVIDER
//
// GetX controller for the Contact Update feature.
//
// Data sources:
//   Phone  -> OTP-based approval workflow. Current phone comes
//             from the Loan Dashboard response
//             (data.lead.borrowers[0].phone, parsed into
//             LoanDetailsModel.borrower.phone). The NEW number is
//             user input. Flow: OTP to current phone (verify via
//             /consumer/otp/verify, token ignored) → OTP to new
//             phone (verify via /consumer/phone/otp/verify → the
//             backend creates the update request). The saved
//             phone is NEVER changed locally and the returned
//             token from /consumer/otp/verify is NEVER persisted.
//             The legacy PATCH .../me/phone path is preserved on
//             the service but no longer used by the UI.
//   Address-> the address ALREADY fetched by the Loan Dashboard
//             response (data.lead.borrowers[0].address, parsed
//             into LoanDetailsModel.borrower.address). No extra
//             GET is performed here.
//
//   LoanAddress.id  -> PUT .../customer/address/:id   (:id)
//   LoanAddress.cid -> AddressUpdateRequest body "cid"
//
// Neither id nor cid is ever invented or derived.
// ============================================================

// ============================================================
// PHONE UPDATE STEP
//
// Drives the OTP-based phone number update UI:
//   1. enterNewPhone      -> user enters the NEW number
//   2. verifyCurrentPhone -> OTP entry for the CURRENT phone
//   3. verifyNewPhone     -> OTP entry for the NEW phone
// ============================================================

enum PhoneUpdateStep {
  enterNewPhone,
  verifyCurrentPhone,
  verifyNewPhone,
}

class ContactUpdateProvider extends GetxController {
  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  static const int _expectedPhoneDigits = 10;

  // ============================================================
  // DEPENDENCIES
  //
  // Both services/controllers are resolved from the locator,
  // mirroring LoanDashboardProvider. ContactUpdateService is
  // expected to be registered alongside this controller by the
  // feature binding; LoanDashboardProvider is already alive
  // because Contact Update opens from the Loan Dashboard.
  // ============================================================

  final ContactUpdateService _contactUpdateService;

  final LoanDashboardProvider _loanDashboardProvider;

  ContactUpdateProvider()
      : _contactUpdateService =
            Get.find<ContactUpdateService>(),
        _loanDashboardProvider =
            Get.find<LoanDashboardProvider>();

  // ============================================================
  // UI STATE
  //
  // Shared by both flows: loading flag, last error and last
  // success message. Success carries the backend message
  // (e.g. "Successfully updated phone number").
  // ============================================================

  final isLoading = false.obs;

  final errorMessage = RxnString();

  final successMessage = RxnString();

  // ============================================================
  // PHONE UPDATE (OTP) STATE
  //
  // Fully independent of AuthProvider's login OTP state so the
  // login flow and its token handling stay completely isolated.
  // ============================================================

  /// Drives the OTP-based phone update UI.
  final phoneUpdateStep = PhoneUpdateStep.enterNewPhone.obs;

  /// Countdown shared by both OTP steps (current + new phone).
  final otpCountdown = 30.obs;

  /// Becomes true once the countdown reaches zero, enabling resend.
  final canResendOtp = false.obs;

  Timer? _otpTimer;

  /// NEW number captured at [beginPhoneUpdate]; never persisted
  /// and never used to change the saved phone locally.
  String? _pendingNewPhone;

  // ============================================================
  // EXISTING ADDRESS ACCESS
  //
  // Read-only view over the Loan Dashboard response. Nothing is
  // refetched; when the dashboard has no address the getters
  // resolve to null / '' and updates fail fast below.
  // ============================================================

  LoanAddress? get currentAddress =>
      _loanDashboardProvider.loanDetails.value?.borrower
          ?.address;

  /// Address Update API ":id", verbatim from the parsed
  /// address object.
  String get addressId => currentAddress?.id ?? '';

  /// Whether an updatable address exists (id present).
  bool get hasAddress => addressId.isNotEmpty;

  /// Current saved values for pre-filling the edit form,
  /// built with AddressUpdateRequest.fromLoanAddress so the
  /// submitted shape starts identical to the stored payload.
  /// Null when the dashboard provided no address.
  AddressUpdateRequest? get initialAddressRequest {
    final address = currentAddress;

    if (address == null) {
      return null;
    }

    return AddressUpdateRequest.fromLoanAddress(address);
  }

  // ============================================================
  // PHONE NUMBER UPDATE
  //
  // LEGACY direct-update path:
  //
  //   PATCH /api/v1/consumer/customer/me/phone
  //   { "phone": "9392113585" }
  //
  // Kept intact for this phase but the Phone Update UI no longer
  // calls it. The OTP-based workflow below is now the entry
  // point for changing a phone number.
  //
  // Returns true on success; exposes errorMessage /
  // successMessage for the UI either way.
  // ============================================================

  Future<bool> updatePhone(String phone) async {
    final digits =
        phone.replaceAll(RegExp('[^0-9]'), '');

    if (digits.length != _expectedPhoneDigits) {
      errorMessage.value =
          'Enter a valid $_expectedPhoneDigits-digit phone number.';
      successMessage.value = null;
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final response =
          await _contactUpdateService.updatePhone(
        PhoneUpdateRequest(phone: digits),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to update your phone number.';
        return false;
      }

      successMessage.value =
          response.message.isNotEmpty
              ? response.message
              : 'Phone number updated successfully.';
      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — CURRENT SAVED NUMBER
  //
  // The current/approved phone comes from the Loan Dashboard
  // response. It is read-only here and is NEVER overwritten with
  // the new number.
  // ============================================================

  String get currentPhone =>
      _loanDashboardProvider.loanDetails.value?.borrower
          ?.phone ??
      '';

  // ============================================================
  // PHONE UPDATE (OTP) — STEP 1: ENTER NEW NUMBER
  //
  // Validates the NEW number (exactly 10 digits), then sends an
  // OTP to the CURRENT saved number using the existing
  // /consumer/otp/request endpoint.
  //
  // Returns true on success; exposes errorMessage /
  // successMessage for the UI either way.
  // ============================================================

  Future<bool> beginPhoneUpdate(String newPhone) async {
    if (isLoading.value) {
      return false;
    }

    final digits =
        newPhone.replaceAll(RegExp('[^0-9]'), '');

    if (digits.length != _expectedPhoneDigits) {
      errorMessage.value =
          'Enter a valid $_expectedPhoneDigits-digit phone number.';
      successMessage.value = null;
      return false;
    }

    final current = currentPhone;

    if (current.isEmpty) {
      errorMessage.value =
          'No saved phone number was found to verify.';
      successMessage.value = null;
      return false;
    }

    _pendingNewPhone = digits;

    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final response =
          await _contactUpdateService.requestCurrentPhoneOtp(
        RequestOtpRequest(
          countryCode: '+91',
          phone: current,
        ),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send OTP. Please try again.';
        return false;
      }

      _startOtpTimer();

      phoneUpdateStep.value =
          PhoneUpdateStep.verifyCurrentPhone;

      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — STEP 2: VERIFY CURRENT PHONE
  //
  // Verifies the OTP sent to the CURRENT number via the existing
  // /consumer/otp/verify endpoint. The token returned by that
  // endpoint is deliberately IGNORED: it is never saved and the
  // existing session token remains unchanged. On success the OTP
  // for the NEW number is requested automatically.
  //
  // Returns true on success; exposes errorMessage /
  // successMessage for the UI either way.
  // ============================================================

  Future<bool> verifyCurrentPhoneOtp(String otp) async {
    if (isLoading.value) {
      return false;
    }

    final current = currentPhone;

    if (current.isEmpty) {
      errorMessage.value =
          'No saved phone number was found to verify.';
      successMessage.value = null;
      return false;
    }

    final digits = _normalizeOtp(otp);

    if (digits.length != 6) {
      errorMessage.value = 'Please enter the 6-digit OTP.';
      successMessage.value = null;
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final response =
          await _contactUpdateService.verifyCurrentPhoneOtp(
        VerifyOtpRequest(
          countryCode: '+91',
          phone: current,
          otp: digits,
        ),
      );

      if (!response.success) {
        errorMessage.value =
            _getOtpErrorMessage(response.message);
        return false;
      }

      return await _requestNewPhoneOtp();
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — REQUEST NEW-PHONE OTP
  //
  // Sends the OTP to the NEW number via the authenticated
  // /consumer/phone/otp/request endpoint (ApiService attaches the
  // existing Bearer automatically). Moves the workflow to the
  // new-phone OTP step on success.
  // ============================================================

  Future<bool> _requestNewPhoneOtp() async {
    final newPhone = _pendingNewPhone;

    if (newPhone == null || newPhone.isEmpty) {
      errorMessage.value =
          'New phone number is missing. Please start again.';
      return false;
    }

    try {
      final response =
          await _contactUpdateService.requestNewPhoneOtp(
        RequestOtpRequest(
          countryCode: '+91',
          phone: newPhone,
        ),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send OTP to your new mobile number.';
        return false;
      }

      _startOtpTimer();

      phoneUpdateStep.value = PhoneUpdateStep.verifyNewPhone;

      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — STEP 3: VERIFY NEW PHONE
  //
  // Verifies the OTP sent to the NEW number via the authenticated
  // /consumer/phone/otp/verify endpoint. On success the backend
  // has created the phone update request. The saved phone is
  // never changed locally.
  //
  // Returns true on success; exposes errorMessage /
  // successMessage for the UI either way.
  // ============================================================

  Future<bool> verifyNewPhoneOtp(String otp) async {
    if (isLoading.value) {
      return false;
    }

    final newPhone = _pendingNewPhone;

    if (newPhone == null || newPhone.isEmpty) {
      errorMessage.value =
          'New phone number is missing. Please start again.';
      successMessage.value = null;
      return false;
    }

    final digits = _normalizeOtp(otp);

    if (digits.length != 6) {
      errorMessage.value = 'Please enter the 6-digit OTP.';
      successMessage.value = null;
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final response =
          await _contactUpdateService.verifyNewPhoneOtp(
        VerifyOtpRequest(
          countryCode: '+91',
          phone: newPhone,
          otp: digits,
        ),
      );

      if (!response.success) {
        errorMessage.value =
            _getOtpErrorMessage(response.message);
        return false;
      }

      successMessage.value =
          response.message.isNotEmpty
              ? response.message
              : 'Phone update request sent successfully.';

      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — RESEND
  //
  // Current-phone OTP resends through /consumer/otp/request;
  // new-phone OTP resends through /consumer/phone/otp/request.
  // Resend is gated by the countdown + loading state so no
  // duplicate API calls can occur.
  // ============================================================

  Future<bool> resendCurrentPhoneOtp() async {
    if (!canResendOtp.value || isLoading.value) {
      return false;
    }

    final current = currentPhone;

    if (current.isEmpty) {
      errorMessage.value =
          'No saved phone number was found to verify.';
      return false;
    }

    errorMessage.value = null;

    try {
      isLoading.value = true;

      final response =
          await _contactUpdateService.requestCurrentPhoneOtp(
        RequestOtpRequest(
          countryCode: '+91',
          phone: current,
        ),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send OTP. Please try again.';
        return false;
      }

      _startOtpTimer();

      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resendNewPhoneOtp() async {
    if (!canResendOtp.value || isLoading.value) {
      return false;
    }

    final newPhone = _pendingNewPhone;

    if (newPhone == null || newPhone.isEmpty) {
      errorMessage.value =
          'New phone number is missing. Please start again.';
      return false;
    }

    errorMessage.value = null;

    try {
      isLoading.value = true;

      final response =
          await _contactUpdateService.requestNewPhoneOtp(
        RequestOtpRequest(
          countryCode: '+91',
          phone: newPhone,
        ),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send OTP to your new mobile number.';
        return false;
      }

      _startOtpTimer();

      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PHONE UPDATE (OTP) — RESET
  //
  // Resets the workflow back to the new-number entry step. Called
  // after the "Phone Update Request Sent" popup is dismissed and
  // when the flow starts over. The saved phone remains untouched.
  // ============================================================

  void resetPhoneUpdate() {
    _otpTimer?.cancel();

    phoneUpdateStep.value = PhoneUpdateStep.enterNewPhone;
    otpCountdown.value = 30;
    canResendOtp.value = false;
    _pendingNewPhone = null;
    errorMessage.value = null;
    successMessage.value = null;
    isLoading.value = false;
  }

  // ============================================================
  // OTP COUNTDOWN
  // ============================================================

  void _startOtpTimer() {
    _otpTimer?.cancel();

    otpCountdown.value = 30;
    canResendOtp.value = false;

    _otpTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (otpCountdown.value > 0) {
          otpCountdown.value--;
        } else {
          canResendOtp.value = true;
          timer.cancel();
        }
      },
    );
  }

  String _normalizeOtp(String otp) {
    return otp.replaceAll(RegExp('[^0-9]'), '');
  }

  String _getOtpErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid') &&
        lowerMessage.contains('otp')) {
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
  // ADDRESS UPDATE
  //
  // [request] starts as initialAddressRequest() (the saved
  // values) and may carry any user-edited fields. The URL id
  // always comes from the parsed LoanAddress.id.
  //
  // Returns true on success; exposes errorMessage /
  // successMessage for the UI either way.
  // ============================================================

  Future<bool> updateAddress(
    AddressUpdateRequest request,
  ) async {
    final id = addressId;

    if (id.isEmpty) {
      errorMessage.value =
          'No saved address was found to update.';
      successMessage.value = null;
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;
      successMessage.value = null;

      final response =
          await _contactUpdateService.updateAddress(
        addressId: id,
        request: request,
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to update your address.';
        return false;
      }

      successMessage.value =
          response.message.isNotEmpty
              ? response.message
              : 'Address updated successfully.';
      return true;
    } catch (error) {
      errorMessage.value = _getErrorMessage(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // API ERROR MESSAGE
  //
  // Same mapping conventions as LoanDashboardProvider.
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Unable to update your details.';
    }

    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (lowerMessage.contains('connect')) {
      return 'Unable to connect to the server.';
    }

    if (lowerMessage.contains('unauthorized') ||
        lowerMessage.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    return message;
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    super.onClose();
  }
}
