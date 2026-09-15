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

// ============================================================
// CONTACT UPDATE WORKFLOW STATUS REQUEST
//
//   POST /api/v1/compliant/query
//
// The single query endpoint is shared by both Contact Update
// workflows; the requested workflow is selected by issueType:
//   7 -> Phone update
//   6 -> Address update
//
// These issueType values belong exclusively to the Contact Update
// workflow query and must NOT be added to ComplaintCreateRequest.
// ============================================================

class ContactUpdateStatusRequest {
  final int issueType;

  const ContactUpdateStatusRequest({
    required this.issueType,
  });

  static const int phoneUpdate = 7;

  static const int addressUpdate = 6;

  Map<String, dynamic> toJson() {
    return {
      'issueType': issueType,
    };
  }
}

// ============================================================
// CONTACT UPDATE STATUS MAPPING  *** BACKEND CONFIRMED ***
//
// Backend-confirmed meaning of the status integer returned by
// POST /api/v1/compliant/query for the Contact Update workflows:
//   1 = Pending   (request submitted, under review)
//   2 = Approved  (request approved)
//   3 = Rejected  (request rejected; comments may explain why)
//
// This mapping belongs EXCLUSIVELY to the Contact Update workflow
// query and must NOT be applied to ComplaintModel or any other
// status domain.
//
// Derived UI behaviour:
//   - Pending  -> editable form hidden; request card shows Pending
//   - Approved -> editable form available again (green status)
//   - Rejected -> editable form available again (red status)
// ============================================================

class ContactUpdateStatusMapping {
  /// Whether the backend has confirmed the workflow status meaning.
  static const bool isBackendConfirmed = true;

  /// Backend-confirmed "pending" status value.
  static const int pending = 1;

  /// Backend-confirmed "approved" status value.
  static const int approved = 2;

  /// Backend-confirmed "rejected" status value.
  static const int rejected = 3;

  /// Human label for a workflow status value.
  ///
  /// Uses the backend-confirmed mapping; unknown values fall back
  /// to the raw integer rather than inventing a label.
  static String label(int status) {
    if (status == pending) {
      return 'Pending';
    }

    if (status == approved) {
      return 'Approved';
    }

    if (status == rejected) {
      return 'Rejected';
    }

    return '$status';
  }
}

// ============================================================
// PHONE UPDATE STATUS
//
// "data" payload of the workflow query for issueType 7.
// ============================================================

class PhoneUpdateStatusModel {
  final String id;
  final String newPhone;
  final String comments;
  final int status;

  const PhoneUpdateStatusModel({
    required this.id,
    required this.newPhone,
    required this.comments,
    required this.status,
  });

  factory PhoneUpdateStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PhoneUpdateStatusModel(
      id: _toString(json['id']),
      newPhone: _toString(json['newPhone']),
      comments: _toString(json['comments']),
      status: _toInt(json['status']),
    );
  }
}

class PhoneUpdateStatusResponse {
  final bool success;
  final String message;
  final PhoneUpdateStatusModel? data;

  const PhoneUpdateStatusResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PhoneUpdateStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];

    return PhoneUpdateStatusResponse(
      success: json['success'] == true,
      message: _toString(json['message']),
      data: rawData is Map
          ? PhoneUpdateStatusModel.fromJson(
              Map<String, dynamic>.from(rawData),
            )
          : null,
    );
  }
}

// ============================================================
// ADDRESS UPDATE STATUS
//
// "data" payload of the workflow query for issueType 6.
//
// oldAddress / newAddress are kept as raw maps: their schema is
// backend-owned and intentionally NOT forced into LoanAddress.
// The UI compares newAddress against the authoritative saved
// LoanAddress via changedFields() so only genuinely changed
// fields are displayed.
// ============================================================

class AddressUpdateStatusModel {
  final String id;
  final Map<String, dynamic>? oldAddress;
  final Map<String, dynamic>? newAddress;
  final String comments;
  final int status;

  const AddressUpdateStatusModel({
    required this.id,
    required this.oldAddress,
    required this.newAddress,
    required this.comments,
    required this.status,
  });

  factory AddressUpdateStatusModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AddressUpdateStatusModel(
      id: _toString(json['id']),
      oldAddress: _asMap(json['oldAddress']),
      newAddress: _asMap(json['newAddress']),
      comments: _toString(json['comments']),
      status: _toInt(json['status']),
    );
  }

  /// Fields that differ between the current saved address and the
  /// address requested in this workflow.
  ///
  /// Compares the authoritative [LoanAddress] (customer/loan data
  /// is always the source of truth) against the backend `newAddress`
  /// map. Only genuinely changed fields are returned, in the same
  /// order shown by the saved-address card. Null/empty values are
  /// treated as empty so requests that omit unchanged fields never
  /// produce duplicate or irrelevant entries. The saved address is
  /// never modified here.
  List<AddressFieldChange> changedFields(LoanAddress current) {
    final requested = newAddress ?? const <String, dynamic>{};

    var changes = <AddressFieldChange>[];

    String read(String key) {
      final raw = requested[key];

      if (raw == null) {
        return '';
      }

      return raw.toString().trim();
    }

    void compare({
      required String label,
      required String currentValue,
      required String key,
    }) {
      final requestValue = read(key);

      if (requestValue == currentValue.trim()) {
        return;
      }

      changes = [
        ...changes,
        AddressFieldChange(
          label: label,
          oldValue: currentValue.trim(),
          newValue: requestValue,
        ),
      ];
    }

    compare(label: 'House Number', currentValue: current.houseNumber, key: 'houseNumber');
    compare(label: 'Floor Number', currentValue: current.floorNumber, key: 'floorNumber');
    compare(label: 'Building Name', currentValue: current.buildingName, key: 'buildingName');
    compare(label: 'Apartment Name', currentValue: current.apartmentName, key: 'apartmentName');
    compare(label: 'Street Name', currentValue: current.streetName, key: 'streetName');
    compare(label: 'Address Line 1', currentValue: current.addressLine1, key: 'addressLine1');
    compare(label: 'Address Line 2', currentValue: current.addressLine2, key: 'addressLine2');
    compare(label: 'Landmark', currentValue: current.landmark, key: 'landmark');
    compare(label: 'Village', currentValue: current.village, key: 'village');
    compare(label: 'District', currentValue: current.district, key: 'district');
    compare(label: 'City', currentValue: current.city, key: 'city');
    compare(label: 'State', currentValue: current.state, key: 'state');
    compare(label: 'Country', currentValue: current.country, key: 'country');
    compare(label: 'Pincode', currentValue: current.pincode, key: 'pincode');
    compare(label: 'Address Type', currentValue: current.addressType, key: 'addressType');

    return changes;
  }
}

// ============================================================
// ADDRESS FIELD CHANGE
//
// Read-only representation of a single changed address field for
// the Address Update request card ("Changed Fields" section).
// ============================================================

class AddressFieldChange {
  final String label;
  final String oldValue;
  final String newValue;

  const AddressFieldChange({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });
}

class AddressUpdateStatusResponse {
  final bool success;
  final String message;
  final AddressUpdateStatusModel? data;

  const AddressUpdateStatusResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddressUpdateStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];

    return AddressUpdateStatusResponse(
      success: json['success'] == true,
      message: _toString(json['message']),
      data: rawData is Map
          ? AddressUpdateStatusModel.fromJson(
              Map<String, dynamic>.from(rawData),
            )
          : null,
    );
  }
}

// ============================================================
// SAFE JSON HELPERS
// ============================================================

String _toString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim()) ?? 0;
  }

  return 0;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}
