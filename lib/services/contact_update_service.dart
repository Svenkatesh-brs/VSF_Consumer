import '../models/contact_update_model.dart';
import '../models/request_otp_model.dart';
import '../models/verify_otp_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

// ============================================================
// CONTACT UPDATE SERVICE
//
// Write operations of the Contact Update feature. Both reuse
// ApiService; neither fetches data — the current address is
// already available from the Loan Dashboard response
// (LoanDetailsModel.borrower.address).
// ============================================================

class ContactUpdateService {
  ContactUpdateService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  // ============================================================
  // PHONE NUMBER UPDATE
  //
  //   PATCH /api/v1/consumer/customer/me/phone
  // ============================================================

  Future<ContactUpdateResponse> updatePhone(
    PhoneUpdateRequest request,
  ) async {
    final response = await _apiService.patch(
      AppConstants.updatePhone,
      data: request.toJson(),
    );

    return _parseResponse(
      response.data,
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // REQUEST CURRENT-PHONE OTP
  //
  //   POST /api/v1/consumer/otp/request
  //
  // Sends the OTP to the currently saved phone number. This is
  // the same endpoint used by login, so ApiService does NOT
  // attach the Bearer header here.
  // ============================================================

  Future<RequestOtpResponse> requestCurrentPhoneOtp(
    RequestOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.requestOtp,
      data: request.toJson(),
    );

    return RequestOtpResponse.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  // ============================================================
  // VERIFY CURRENT-PHONE OTP
  //
  //   POST /api/v1/consumer/otp/verify
  //
  // The endpoint returns a login token because login also uses
  // it. During Contact Update that token MUST NOT be persisted
  // or used to replace the existing session token, so the
  // response is parsed into ContactUpdateResponse, which carries
  // only success/message/data and deliberately ignores the
  // token field. StorageService is never touched here.
  // ============================================================

  Future<ContactUpdateResponse> verifyCurrentPhoneOtp(
    VerifyOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.verifyOtp,
      data: request.toJson(),
    );

    return _parseResponse(
      response.data,
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // REQUEST NEW-PHONE OTP
  //
  //   POST /api/v1/consumer/phone/otp/request
  //
  // Requires the existing authenticated session. ApiService
  // automatically attaches the Bearer token (this path is not
  // part of the OTP login exclusion list).
  // ============================================================

  Future<RequestOtpResponse> requestNewPhoneOtp(
    RequestOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.phoneOtpRequest,
      data: request.toJson(),
    );

    return RequestOtpResponse.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  // ============================================================
  // VERIFY NEW-PHONE OTP
  //
  //   POST /api/v1/consumer/phone/otp/verify
  //
  // Requires the existing authenticated session. ApiService
  // automatically attaches the Bearer token. On success the
  // backend creates the phone update request.
  // ============================================================

  Future<PhoneOtpVerifyResponse> verifyNewPhoneOtp(
    VerifyOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.phoneOtpVerify,
      data: request.toJson(),
    );

    return _parsePhoneOtpVerifyResponse(
      response.data,
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // ADDRESS UPDATE
  //
  //   PUT /api/v1/consumer/customer/address/:id
  //
  // [addressId] comes verbatim from LoanAddress.id parsed by
  // the Loan Dashboard response; the body carries cid and the
  // documented address fields (see AddressUpdateRequest).
  // ============================================================

  Future<ContactUpdateResponse> updateAddress({
    required String addressId,
    required AddressUpdateRequest request,
  }) async {
    if (addressId.isEmpty) {
      throw ApiException(
        message: 'No saved address was found to update.',
      );
    }

    final response = await _apiService.put(
      '${AppConstants.updateAddress}$addressId',
      data: request.toJson(),
    );

    return _parseResponse(
      response.data,
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // RESPONSE VALIDATION
  //
  // Handles the success envelope with "data": null without
  // treating it as an error.
  // ============================================================

  ContactUpdateResponse _parseResponse(
    dynamic raw, {
    int? statusCode,
  }) {
    if (raw is Map<String, dynamic>) {
      return ContactUpdateResponse.fromJson(raw);
    }

    if (raw is Map) {
      return ContactUpdateResponse.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    throw ApiException(
      statusCode: statusCode,
      message: 'Invalid response received from server.',
    );
  }

  // ============================================================
  // PHONE OTP VERIFY RESPONSE VALIDATION
  // ============================================================

  PhoneOtpVerifyResponse _parsePhoneOtpVerifyResponse(
    dynamic raw, {
    int? statusCode,
  }) {
    if (raw is Map<String, dynamic>) {
      return PhoneOtpVerifyResponse.fromJson(raw);
    }

    if (raw is Map) {
      return PhoneOtpVerifyResponse.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }

    throw ApiException(
      statusCode: statusCode,
      message: 'Invalid response received from server.',
    );
  }
}
