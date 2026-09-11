import 'loan_details_model.dart';

// ============================================================
// CONTACT UPDATE MODELS
//
// Request/response bodies for the Contact Update feature:
//
//   PATCH /api/v1/consumer/customer/me/phone
//   PUT   /api/v1/consumer/customer/address/:id
//
// The address request is populated from the address object
// already fetched by the Loan Dashboard response
// (data.lead.borrowers[0].address, parsed as LoanAddress):
//
//   LoanAddress.id  -> URL :id (not part of the body)
//   LoanAddress.cid -> body "cid"
//
// No fields are invented; only documented keys are sent.
// ============================================================

// ============================================================
// PHONE NUMBER UPDATE REQUEST
//
// Body:
//   { "phone": "9392113585" }
// ============================================================

class PhoneUpdateRequest {
  final String phone;

  const PhoneUpdateRequest({
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}

// ============================================================
// ADDRESS UPDATE REQUEST
//
// Body fields (exact backend contract):
//   cid, addressLine1, addressLine2, landmark, pincode,
//   state, city, country, district, village, houseNumber,
//   floorNumber, streetName, apartmentName, buildingName,
//   addressType
// ============================================================

class AddressUpdateRequest {
  final String cid;

  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String pincode;
  final String state;
  final String city;
  final String country;
  final String district;
  final String village;
  final String houseNumber;
  final String floorNumber;
  final String streetName;
  final String apartmentName;
  final String buildingName;
  final String addressType;

  const AddressUpdateRequest({
    required this.cid,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.pincode,
    required this.state,
    required this.city,
    required this.country,
    required this.district,
    required this.village,
    required this.houseNumber,
    required this.floorNumber,
    required this.streetName,
    required this.apartmentName,
    required this.buildingName,
    required this.addressType,
  });

  /// Builds the request body from the address already parsed
  /// out of the existing loan response. Every value is taken
  /// verbatim from [address]; nothing is derived.
  factory AddressUpdateRequest.fromLoanAddress(
    LoanAddress address,
  ) {
    return AddressUpdateRequest(
      cid: address.cid,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      landmark: address.landmark,
      pincode: address.pincode,
      state: address.state,
      city: address.city,
      country: address.country,
      district: address.district,
      village: address.village,
      houseNumber: address.houseNumber,
      floorNumber: address.floorNumber,
      streetName: address.streetName,
      apartmentName: address.apartmentName,
      buildingName: address.buildingName,
      addressType: address.addressType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cid': cid,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'landmark': landmark,
      'pincode': pincode,
      'state': state,
      'city': city,
      'country': country,
      'district': district,
      'village': village,
      'houseNumber': houseNumber,
      'floorNumber': floorNumber,
      'streetName': streetName,
      'apartmentName': apartmentName,
      'buildingName': buildingName,
      'addressType': addressType,
    };
  }
}

// ============================================================
// CONTACT UPDATE RESPONSE
//
// Shared envelope of both endpoints. On success the phone
// update returns an explicit JSON null for "data":
//
//   { "data": null,
//     "message": "Successfully updated phone number",
//     "success": true }
//
// so data stays dynamic and may legitimately be null.
// ============================================================

class ContactUpdateResponse {
  final bool success;
  final String message;

  // Null on success for both endpoints; never typed beyond
  // dynamic because the backend documents no payload.
  final dynamic data;

  const ContactUpdateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ContactUpdateResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ContactUpdateResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
    );
  }
}

// ============================================================
// PHONE OTP VERIFY RESPONSE
//
//   POST /api/v1/consumer/phone/otp/verify
//
// Success envelope:
//   { "data": "8639144157",
//     "message": "Phone number verified and update request created successfully",
//     "success": true }
//
// data carries the verified (new) phone number as a string; it
// stays dynamic here because the request-creation flow may vary
// the payload shape. The token returned by the login-centric
// /consumer/otp/verify endpoint is deliberately NOT declared in
// this model so Contact Update never persists it.
// ============================================================

class PhoneOtpVerifyResponse {
  final bool success;
  final String message;
  final dynamic data;

  const PhoneOtpVerifyResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PhoneOtpVerifyResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return PhoneOtpVerifyResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
    );
  }
}
