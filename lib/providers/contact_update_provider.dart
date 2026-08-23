import 'package:get/get.dart';

import '../models/contact_update_model.dart';
import '../models/loan_details_model.dart';
import '../services/contact_update_service.dart';
import 'loan_dashboard_provider.dart';

// ============================================================
// CONTACT UPDATE PROVIDER
//
// GetX controller for the Contact Update feature.
//
// Data sources:
//   Phone  -> user input, PATCH /api/v1/consumer/customer/me/phone
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
  // Validates the input contains exactly 10 digits before any
  // network call, then submits the digits to the phone API.
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
}
