// ============================================================
// LOAN DETAILS MODEL
//
// Data required by the Loan Details screen, sourced from the
// loan API response:
//
//   GET /api/v1/consumer/loan/:id  ->  data{...}
//
// Includes loan identity, scheme, borrower, guarantors, asset
// and disbursement summary. Every nested object is optional and
// parsed defensively.
// ============================================================

class LoanDetailsModel {
  final String loanId;
  final String loanNo;

  // Raw backend status. API status 5 = Inactive, all other
  // statuses = Active (same convention as the Home feature).
  final int statusRaw;

  final String branchName;
  final String productName;
  final String loanTypeName;
  final String schemeName;

  final double principalAmount;
  final double interestRate;
  final double irr;
  final double emiAmount;
  final int numberOfInstallments;

  // Epoch milliseconds; null when the API provides none.
  final int? agreementDateMs;
  final int? loanCreationDateMs;
  final int? emiStartDateMs;

  final LoanBorrowerDetail? borrower;
  final List<LoanGuarantorDetail> guarantors;
  final LoanAssetDetail? asset;
  final LoanDisbursementSummary? disbursementSummary;

  const LoanDetailsModel({
    required this.loanId,
    required this.loanNo,
    required this.statusRaw,
    required this.branchName,
    required this.productName,
    required this.loanTypeName,
    required this.schemeName,
    required this.principalAmount,
    required this.interestRate,
    required this.irr,
    required this.emiAmount,
    required this.numberOfInstallments,
    required this.agreementDateMs,
    required this.loanCreationDateMs,
    required this.emiStartDateMs,
    required this.borrower,
    required this.guarantors,
    required this.asset,
    required this.disbursementSummary,
  });

  factory LoanDetailsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // --------------------------------------------------------
    // NESTED OBJECTS (all optional)
    // --------------------------------------------------------

    final lead = _asMap(json['lead']);
    final productType =
        lead == null ? null : _asMap(lead['productType']);
    final loanType =
        lead == null ? null : _asMap(lead['loanType']);
    final scheme =
        lead == null ? null : _asMap(lead['loanScheme']);
    final branch =
        lead == null ? null : _asMap(lead['branch']);
    final payment = _asMap(json['payment']);

    final schemes = _mapList(
      json['loanSchemes'],
      (m) => m,
    );

    // --------------------------------------------------------
    // BORROWER: first entry of lead.borrowers[]
    // --------------------------------------------------------

    final borrowers = lead == null
        ? <LoanBorrowerDetail>[]
        : _mapList(
            lead['borrowers'],
            LoanBorrowerDetail.fromJson,
          );

    return LoanDetailsModel(
      loanId: _toStr(json['id']),
      loanNo: _toStr(json['loanNo']),
      statusRaw: _toInt(json['status']),
      branchName:
          branch == null ? '' : _toStr(branch['name']),
      productName: productType == null
          ? ''
          : _toStr(productType['name']),
      loanTypeName:
          loanType == null ? '' : _toStr(loanType['name']),
      schemeName:
          scheme == null ? '' : _toStr(scheme['name']),
      principalAmount:
          _toDouble(json['principalAmount']),
      interestRate: _toDouble(json['interest']),
      irr: _toDouble(json['irr']),
      emiAmount: schemes.isEmpty
          ? 0
          : _toDouble(schemes.first['emi']),
      numberOfInstallments: schemes.isEmpty
          ? 0
          : _toInt(schemes.first['noOfInstallments']),
      agreementDateMs:
          _toMillis(json['agreementDate']),
      loanCreationDateMs: payment == null
          ? null
          : _toMillis(payment['loanCreationDate']),
      emiStartDateMs: payment == null
          ? _toMillis(json['installmentDate'])
          : _toMillis(payment['emiStartDate']) ??
              _toMillis(json['installmentDate']),
      borrower:
          borrowers.isEmpty ? null : borrowers.first,
      guarantors: lead == null
          ? <LoanGuarantorDetail>[]
          : _mapList(
              lead['guarantors'],
              LoanGuarantorDetail.fromJson,
            ),
      asset: lead == null
          ? null
          : _parseAsset(lead['asset']),
      disbursementSummary: LoanDisbursementSummary.tryParse(
        json['disbursementSummary'],
      ),
    );
  }

  String get displayStatus =>
      statusRaw == 5 ? 'Inactive' : 'Active';

  static LoanAssetDetail? _parseAsset(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return LoanAssetDetail.fromJson(
      Map<String, dynamic>.from(value),
    );
  }
}

// ============================================================
// BORROWER DETAIL
// ============================================================

class LoanBorrowerDetail {
  final String id;
  final String cifId;
  final String name;
  final String phone;
  final String dob;
  final String gender;
  final String relation;

  final String addressLine1;
  final String city;
  final String state;
  final String pincode;

  final String bankName;
  final String accountNumber;
  final String ifscCode;

  const LoanBorrowerDetail({
    required this.id,
    required this.cifId,
    required this.name,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.relation,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
  });

  factory LoanBorrowerDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    // Address and bank blocks may be missing entirely.
    final address = _asMap(json['address']);
    final bank = _asMap(json['bank']);

    return LoanBorrowerDetail(
      id: _toStr(json['id']),
      cifId: _toStr(json['cifId']),
      name:
          '${_toStr(json['firstName'])} ${_toStr(json['lastName'])}'
              .trim(),
      phone: _toStr(json['phone']),
      dob: _toStr(json['dob']),
      gender: _toStr(json['gender']),
      relation: _toStr(json['relation']),
      addressLine1: address == null
          ? ''
          : _toStr(address['addressLine1']),
      city:
          address == null ? '' : _toStr(address['city']),
      state:
          address == null ? '' : _toStr(address['state']),
      pincode: address == null
          ? ''
          : _toStr(address['pincode']),
      bankName:
          bank == null ? '' : _toStr(bank['bankName']),
      accountNumber:
          bank == null ? '' : _toStr(bank['accountNo']),
      ifscCode:
          bank == null ? '' : _toStr(bank['ifscCode']),
    );
  }
}

// ============================================================
// GUARANTOR DETAIL
// ============================================================

class LoanGuarantorDetail {
  final String id;
  final String cifId;
  final String name;
  final String phone;
  final String relation;

  const LoanGuarantorDetail({
    required this.id,
    required this.cifId,
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory LoanGuarantorDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoanGuarantorDetail(
      id: _toStr(json['id']),
      cifId: _toStr(json['cifId']),
      name:
          '${_toStr(json['firstName'])} ${_toStr(json['lastName'])}'
              .trim(),
      phone: _toStr(json['phone']),
      relation: _toStr(json['relation']),
    );
  }
}

// ============================================================
// ASSET (VEHICLE) DETAIL
// ============================================================

class LoanAssetDetail {
  final String registrationNumber;
  final String engineNumber;
  final String chassisNumber;
  final String ownerName;
  final String fuelType;
  final String manufactureYear;

  // variant.class.make.name / variant.name /
  // variant.class.type.name — resolved defensively.
  final String makeName;
  final String modelName;
  final String vehicleType;

  final double invoiceAmount;
  final double onRoadPrice;

  const LoanAssetDetail({
    required this.registrationNumber,
    required this.engineNumber,
    required this.chassisNumber,
    required this.ownerName,
    required this.fuelType,
    required this.manufactureYear,
    required this.makeName,
    required this.modelName,
    required this.vehicleType,
    required this.invoiceAmount,
    required this.onRoadPrice,
  });

  factory LoanAssetDetail.fromJson(
    Map<String, dynamic> json,
  ) {
    final variant = _asMap(json['variant']);
    final vehicleClass = variant == null
        ? null
        : _asMap(variant['class']);
    final make = vehicleClass == null
        ? null
        : _asMap(vehicleClass['make']);
    final type = vehicleClass == null
        ? null
        : _asMap(vehicleClass['type']);

    return LoanAssetDetail(
      registrationNumber:
          _toStr(json['registrationNumber']),
      engineNumber: _toStr(json['engineNumber']),
      chassisNumber: _toStr(json['chassisNumber']),
      ownerName: _toStr(json['ownerName']),
      fuelType: _toStr(json['fuelType']),
      manufactureYear: _toStr(json['manufactureYear']),
      makeName:
          make == null ? '' : _toStr(make['name']),
      modelName: variant == null
          ? ''
          : _toStr(variant['name']),
      vehicleType:
          type == null ? '' : _toStr(type['name']),
      invoiceAmount: _toDouble(json['invoiceAmount']),
      onRoadPrice: _toDouble(json['onRoadPrice']),
    );
  }
}

// ============================================================
// DISBURSEMENT SUMMARY
//
// Authoritative source for displayed amounts
// (data.loanAmount is 0 in the real payload).
// ============================================================

class LoanDisbursementSummary {
  final double totalLoanAmount;
  final double adjustmentsAmount;
  final double advanceEmiAmount;
  final double deductionAmount;
  final double chargeAmount;
  final double downPaymentAmount;
  final double amountToBePaid;

  const LoanDisbursementSummary({
    required this.totalLoanAmount,
    required this.adjustmentsAmount,
    required this.advanceEmiAmount,
    required this.deductionAmount,
    required this.chargeAmount,
    required this.downPaymentAmount,
    required this.amountToBePaid,
  });

  static LoanDisbursementSummary? tryParse(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return LoanDisbursementSummary.fromJson(
      Map<String, dynamic>.from(value),
    );
  }

  factory LoanDisbursementSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoanDisbursementSummary(
      totalLoanAmount:
          _toDouble(json['totalLoanAmount']),
      adjustmentsAmount:
          _toDouble(json['adjustmentsAmount']),
      advanceEmiAmount:
          _toDouble(json['advanceEMIAmount']),
      deductionAmount:
          _toDouble(json['deductionAmount']),
      chargeAmount: _toDouble(json['chargeAmount']),
      downPaymentAmount:
          _toDouble(json['downPaymentAmount']),
      amountToBePaid:
          _toDouble(json['amountToBePaid']),
    );
  }
}

// ============================================================
// SAFE PARSING HELPERS
// ============================================================

String _toStr(dynamic value) {
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

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  return 0.0;
}

/// Epoch-milliseconds parser.
///
/// Accepts numeric values (int/double/numeric string) and ISO-8601
/// strings. Zero dates like "0001-01-01T00:00:00Z" and zero epoch
/// values resolve to null instead of a meaningless timestamp.
int? _toMillis(dynamic value) {
  if (value is num) {
    final ms = value.toInt();

    return ms > 0 ? ms : null;
  }

  if (value is String) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final numeric = int.tryParse(trimmed);

    if (numeric != null) {
      return numeric > 0 ? numeric : null;
    }

    final parsed = DateTime.tryParse(trimmed);

    if (parsed == null) {
      return null;
    }

    final ms = parsed.millisecondsSinceEpoch;

    return ms > 0 ? ms : null;
  }

  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList();
}
