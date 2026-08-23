import '../models/contact_update_model.dart';
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
}
