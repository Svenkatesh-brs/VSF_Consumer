// ============================================================
// HOME API REQUEST MODEL
// ============================================================

class HomeRequest {
  final int page;
  final int recordsPerPage;
  final String searchString;

  const HomeRequest({
    required this.page,
    required this.recordsPerPage,
    required this.searchString,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'recordsPerPage': recordsPerPage,
      'searchString': searchString,
    };
  }
}

// ============================================================
// HOME API RESPONSE MODEL
// ============================================================

class HomeResponse {
  final HomeData? data;
  final String message;
  final int page;
  final int recordsPerPage;
  final bool success;
  final int total;

  const HomeResponse({
    required this.data,
    required this.message,
    required this.page,
    required this.recordsPerPage,
    required this.success,
    required this.total,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      data: json['data'] is Map
          ? HomeData.fromJson(
              Map<String, dynamic>.from(json['data'] as Map),
            )
          : null,
      message: json['message']?.toString() ?? '',
      page: _toInt(json['page']),
      recordsPerPage: _toInt(json['recordsPerPage']),
      success: json['success'] == true,
      total: _toInt(json['total']),
    );
  }
}

// ============================================================
// HOME DATA / CONSUMER
// ============================================================

class HomeData {
  final String id;
  final String cifId;
  final String entityType;
  final String phone;
  final String salutation;
  final String gender;
  final String dob;
  final String careOf;
  final String relationToCare;
  final String firstName;
  final String lastName;
  final String profilePicture;
  final double annualIncome;
  final String maritalStatus;
  final String aadharNo;

  final String? panNo;
  final String? passportNo;
  final String? voterId;
  final String? drivingLicence;
  final String? rationNo;
  final String? gstNo;
  final String? cinNo;
  final String? ckycId;
  final String? email;
  final String? education;
  final String? alternativePhoneNumber;
  final String? contactReference;
  final String? familyBg;
  final String? relation;

  final HomeAddress? address;
  final HomeBank? bank;
  final List<HomeDocument> documents;

  final String createdAt;
  final String updatedAt;

  final List<HomeLoan> loans;

  const HomeData({
    required this.id,
    required this.cifId,
    required this.entityType,
    required this.phone,
    required this.salutation,
    required this.gender,
    required this.dob,
    required this.careOf,
    required this.relationToCare,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.annualIncome,
    required this.maritalStatus,
    required this.aadharNo,
    required this.panNo,
    required this.passportNo,
    required this.voterId,
    required this.drivingLicence,
    required this.rationNo,
    required this.gstNo,
    required this.cinNo,
    required this.ckycId,
    required this.email,
    required this.education,
    required this.alternativePhoneNumber,
    required this.contactReference,
    required this.familyBg,
    required this.relation,
    required this.address,
    required this.bank,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
    required this.loans,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      id: _toString(json['id']),
      cifId: _toString(json['cifId']),
      entityType: _toString(json['entityType']),
      phone: _toString(json['phone']),
      salutation: _toString(json['salutation']),
      gender: _toString(json['gender']),
      dob: _toString(json['dob']),
      careOf: _toString(json['careOf']),
      relationToCare: _toString(json['relationToCare']),
      firstName: _toString(json['firstName']),
      lastName: _toString(json['lastName']),
      profilePicture: _toString(json['profilePicture']),
      annualIncome: _toDouble(json['annualIncome']),
      maritalStatus: _toString(json['maritalStatus']),
      aadharNo: _toString(json['aadharNo']),
      panNo: _nullableString(json['panNo']),
      passportNo: _nullableString(json['passportNo']),
      voterId: _nullableString(json['voterId']),
      drivingLicence: _nullableString(json['drivingLicence']),
      rationNo: _nullableString(json['rationNo']),
      gstNo: _nullableString(json['gstNo']),
      cinNo: _nullableString(json['cinNo']),
      ckycId: _nullableString(json['ckycId']),
      email: _nullableString(json['email']),
      education: _nullableString(json['education']),
      alternativePhoneNumber:
          _nullableString(json['alternativePhoneNumber']),
      contactReference:
          _nullableString(json['contactReference']),
      familyBg: _nullableString(json['familyBg']),
      relation: _nullableString(json['relation']),
      address: json['address'] is Map
          ? HomeAddress.fromJson(
              Map<String, dynamic>.from(json['address'] as Map),
            )
          : null,
      bank: json['bank'] is Map
          ? HomeBank.fromJson(
              Map<String, dynamic>.from(json['bank'] as Map),
            )
          : null,
      documents: _mapList(
        json['documents'],
        HomeDocument.fromJson,
      ),
      createdAt: _toString(json['createdAt']),
      updatedAt: _toString(json['updatedAt']),
      loans: _mapList(
        json['loans'],
        HomeLoan.fromJson,
      ),
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();

    return name.isEmpty ? 'Consumer' : name;
  }
}

// ============================================================
// ADDRESS
// ============================================================

class HomeAddress {
  final String createdBy;
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
  final String createdAt;
  final String updatedAt;

  const HomeAddress({
    required this.createdBy,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeAddress.fromJson(Map<String, dynamic> json) {
    return HomeAddress(
      createdBy: _toString(json['createdBy']),
      cid: _toString(json['cid']),
      addressLine1: _toString(json['addressLine1']),
      addressLine2: _toString(json['addressLine2']),
      landmark: _toString(json['landmark']),
      pincode: _toString(json['pincode']),
      state: _toString(json['state']),
      city: _toString(json['city']),
      country: _toString(json['country']),
      district: _toString(json['district']),
      village: _toString(json['village']),
      houseNumber: _toString(json['houseNumber']),
      floorNumber: _toString(json['floorNumber']),
      streetName: _toString(json['streetName']),
      apartmentName: _toString(json['apartmentName']),
      buildingName: _toString(json['buildingName']),
      addressType: _toString(json['addressType']),
      createdAt: _toString(json['createdAt']),
      updatedAt: _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// BANK
// ============================================================

class HomeBank {
  final String createdBy;
  final String cid;
  final String accountType;
  final String accountNo;
  final String accountName;
  final String bankName;
  final String branchName;
  final String ifscCode;
  final String createdAt;
  final String updatedAt;

  const HomeBank({
    required this.createdBy,
    required this.cid,
    required this.accountType,
    required this.accountNo,
    required this.accountName,
    required this.bankName,
    required this.branchName,
    required this.ifscCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeBank.fromJson(Map<String, dynamic> json) {
    return HomeBank(
      createdBy: _toString(json['createdBy']),
      cid: _toString(json['cid']),
      accountType: _toString(json['accountType']),
      accountNo: _toString(json['accountNo']),
      accountName: _toString(json['accountName']),
      bankName: _toString(json['bankName']),
      branchName: _toString(json['branchName']),
      ifscCode: _toString(json['ifscCode']),
      createdAt: _toString(json['createdAt']),
      updatedAt: _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// DOCUMENT
// ============================================================

class HomeDocument {
  final String createdBy;
  final String cid;
  final String type;
  final String did;
  final String createdAt;
  final String updatedAt;

  const HomeDocument({
    required this.createdBy,
    required this.cid,
    required this.type,
    required this.did,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeDocument.fromJson(Map<String, dynamic> json) {
    return HomeDocument(
      createdBy: _toString(json['createdBy']),
      cid: _toString(json['cid']),
      type: _toString(json['type']),
      did: _toString(json['did']),
      createdAt: _toString(json['createdAt']),
      updatedAt: _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// LOAN
// ============================================================

class HomeLoan {
  final String id;
  final String loanNo;
  final int loanStage;
  final int freezeDate;
  final int closerDate;
  final int closerReminderDate;
  final int step;
  final int status;
  final String leadId;
  final String ledger;

  final List<HomeLoanScheme> loanSchemes;

  final HomePayment? payment;

  final double principalAmount;
  final int agreementDate;
  final int installmentDate;

  final String interestType;
  final double interest;
  final double irr;

  final String workflowId;

  final String? executiveId;
  final String? adminId;
  final String? loanDiscount;

  final String createdBy;
  final String createdAt;
  final String updatedAt;

  final HomeLead? lead;

  final double loanAmount;
  final double totalEMIPaid;
  final double totalLpcReceived;

  const HomeLoan({
    required this.id,
    required this.loanNo,
    required this.loanStage,
    required this.freezeDate,
    required this.closerDate,
    required this.closerReminderDate,
    required this.step,
    required this.status,
    required this.leadId,
    required this.ledger,
    required this.loanSchemes,
    required this.payment,
    required this.principalAmount,
    required this.agreementDate,
    required this.installmentDate,
    required this.interestType,
    required this.interest,
    required this.irr,
    required this.workflowId,
    required this.executiveId,
    required this.adminId,
    required this.loanDiscount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.lead,
    required this.loanAmount,
    required this.totalEMIPaid,
    required this.totalLpcReceived,
  });

  factory HomeLoan.fromJson(Map<String, dynamic> json) {
    return HomeLoan(
      id: _toString(json['id']),
      loanNo: _toString(json['loanNo']),
      loanStage: _toInt(json['loanStage']),
      freezeDate: _toInt(json['freezeDate']),
      closerDate: _toInt(json['closerDate']),
      closerReminderDate:
          _toInt(json['closerReminderDate']),
      step: _toInt(json['step']),
      status: _toInt(json['status']),
      leadId: _toString(json['leadId']),
      ledger: _toString(json['ledger']),
      loanSchemes: _mapList(
        json['loanSchemes'],
        HomeLoanScheme.fromJson,
      ),
      payment: json['payment'] is Map
          ? HomePayment.fromJson(
              Map<String, dynamic>.from(json['payment'] as Map),
            )
          : null,
      principalAmount:
          _toDouble(json['principalAmount']),
      agreementDate:
          _toInt(json['agreementDate']),
      installmentDate:
          _toInt(json['installmentDate']),
      interestType:
          _toString(json['interestType']),
      interest:
          _toDouble(json['interest']),
      irr:
          _toDouble(json['irr']),
      workflowId:
          _toString(json['workflowId']),
      executiveId:
          _nullableString(json['executiveId']),
      adminId:
          _nullableString(json['adminId']),
      loanDiscount:
          _nullableString(json['loanDiscount']),
      createdBy:
          _toString(json['createdBy']),
      createdAt:
          _toString(json['createdAt']),
      updatedAt:
          _toString(json['updatedAt']),
      lead: json['lead'] is Map
          ? HomeLead.fromJson(
              Map<String, dynamic>.from(json['lead'] as Map),
            )
          : null,
      loanAmount:
          _toDouble(json['loanAmount']),
      totalEMIPaid:
          _toDouble(json['totalEMIPaid']),
      totalLpcReceived:
          _toDouble(json['totalLpcReceived']),
    );
  }

  // ------------------------------------------------------------
  // HOME UI HELPERS
  // ------------------------------------------------------------

  String get vehicleNumber {
    return lead?.borrowers.isNotEmpty == true
        ? lead!.borrowers.first.id
        : loanNo;
  }

  String get borrowerName {
    return lead?.borrowers.isNotEmpty == true
        ? lead!.borrowers.first.relation
        : '';
  }

  double get amount {
    return loanAmount;
  }

  String get displayStatus {
    switch (status) {
      case 5:
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}

// ============================================================
// LOAN SCHEME
// ============================================================

class HomeLoanScheme {
  final double emi;
  final int noOfInstallments;

  const HomeLoanScheme({
    required this.emi,
    required this.noOfInstallments,
  });

  factory HomeLoanScheme.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeLoanScheme(
      emi: _toDouble(json['emi']),
      noOfInstallments:
          _toInt(json['noOfInstallments']),
    );
  }
}

// ============================================================
// PAYMENT
// ============================================================

class HomePayment {
  final int loanCreationDate;
  final int emiStartDate;
  final String fileNumber;
  final HomePaymentMethods? methods;

  const HomePayment({
    required this.loanCreationDate,
    required this.emiStartDate,
    required this.fileNumber,
    required this.methods,
  });

  factory HomePayment.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomePayment(
      loanCreationDate:
          _toInt(json['loanCreationDate']),
      emiStartDate:
          _toInt(json['emiStartDate']),
      fileNumber:
          _toString(json['fileNumber']),
      methods: json['methods'] is Map
          ? HomePaymentMethods.fromJson(
              Map<String, dynamic>.from(
                json['methods'] as Map,
              ),
            )
          : null,
    );
  }
}

// ============================================================
// PAYMENT METHODS
// ============================================================

class HomePaymentMethods {
  final dynamic customer;
  final dynamic dealer;
  final dynamic others;
  final dynamic adjustments;
  final dynamic dta;

  const HomePaymentMethods({
    required this.customer,
    required this.dealer,
    required this.others,
    required this.adjustments,
    required this.dta,
  });

  factory HomePaymentMethods.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomePaymentMethods(
      customer: json['customer'],
      dealer: json['dealer'],
      others: json['others'],
      adjustments: json['adjustments'],
      dta: json['dta'],
    );
  }
}

// ============================================================
// LEAD
// ============================================================

class HomeLead {
  final String id;
  final String leadId;
  final dynamic area;
  final double lpInterest;

  final String createdAt;
  final String updatedAt;

  final HomeBranch? branch;
  final HomeCenter? center;
  final HomeCollectionArea? collectionArea;

  final String productType;

  final HomeLoanType? loanType;

  final String loanScheme;
  final String vendor;
  final String sourceType;
  final String source;
  final String loanPurpose;

  final double comfortableEmi;
  final int tenure;
  final double proposedAmount;

  final List<HomeBorrowerReference> borrowers;
  final List<HomeGuarantorReference> guarantors;

  const HomeLead({
    required this.id,
    required this.leadId,
    required this.area,
    required this.lpInterest,
    required this.createdAt,
    required this.updatedAt,
    required this.branch,
    required this.center,
    required this.collectionArea,
    required this.productType,
    required this.loanType,
    required this.loanScheme,
    required this.vendor,
    required this.sourceType,
    required this.source,
    required this.loanPurpose,
    required this.comfortableEmi,
    required this.tenure,
    required this.proposedAmount,
    required this.borrowers,
    required this.guarantors,
  });

  factory HomeLead.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeLead(
      id: _toString(json['id']),
      leadId: _toString(json['leadId']),
      area: json['area'],
      lpInterest: _toDouble(json['lpInterest']),
      createdAt: _toString(json['createdAt']),
      updatedAt: _toString(json['updatedAt']),
      branch: json['branch'] is Map
          ? HomeBranch.fromJson(
              Map<String, dynamic>.from(
                json['branch'] as Map,
              ),
            )
          : null,
      center: json['center'] is Map
          ? HomeCenter.fromJson(
              Map<String, dynamic>.from(
                json['center'] as Map,
              ),
            )
          : null,
      collectionArea: json['collectionArea'] is Map
          ? HomeCollectionArea.fromJson(
              Map<String, dynamic>.from(
                json['collectionArea'] as Map,
              ),
            )
          : null,
      productType: _toString(json['productType']),
      loanType: json['loanType'] is Map
          ? HomeLoanType.fromJson(
              Map<String, dynamic>.from(
                json['loanType'] as Map,
              ),
            )
          : null,
      loanScheme: _toString(json['loanScheme']),
      vendor: _toString(json['vendor']),
      sourceType: _toString(json['sourceType']),
      source: _toString(json['source']),
      loanPurpose: _toString(json['loanPurpose']),
      comfortableEmi:
          _toDouble(json['comfortableEmi']),
      tenure: _toInt(json['tenure']),
      proposedAmount:
          _toDouble(json['proposedAmount']),
      borrowers: _mapList(
        json['borrowers'],
        HomeBorrowerReference.fromJson,
      ),
      guarantors: _mapList(
        json['guarantors'],
        HomeGuarantorReference.fromJson,
      ),
    );
  }
}

// ============================================================
// BRANCH
// ============================================================

class HomeBranch {
  final String id;
  final String name;
  final String prefix;
  final dynamic lpcType;

  const HomeBranch({
    required this.id,
    required this.name,
    required this.prefix,
    required this.lpcType,
  });

  factory HomeBranch.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeBranch(
      id: _toString(json['id']),
      name: _toString(json['name']),
      prefix: _toString(json['prefix']),
      lpcType: json['lpcType'],
    );
  }
}

// ============================================================
// CENTER
// ============================================================

class HomeCenter {
  final String id;
  final String name;
  final String address;
  final String addressLane1;
  final String famousLandMark;
  final String pincode;
  final String createdAt;
  final String updatedAt;

  const HomeCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.addressLane1,
    required this.famousLandMark,
    required this.pincode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeCenter.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeCenter(
      id: _toString(json['id']),
      name: _toString(json['name']),
      address: _toString(json['address']),
      addressLane1:
          _toString(json['addressLane1']),
      famousLandMark:
          _toString(json['famousLandMark']),
      pincode: _toString(json['pincode']),
      createdAt:
          _toString(json['createdAt']),
      updatedAt:
          _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// COLLECTION AREA
// ============================================================

class HomeCollectionArea {
  final String id;
  final String name;
  final String address;
  final String createdAt;
  final String updatedAt;

  const HomeCollectionArea({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeCollectionArea.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeCollectionArea(
      id: _toString(json['id']),
      name: _toString(json['name']),
      address: _toString(json['address']),
      createdAt:
          _toString(json['createdAt']),
      updatedAt:
          _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// LOAN TYPE
// ============================================================

class HomeLoanType {
  final String id;
  final String name;
  final String prefix;
  final double ltvReduction;
  final String createdAt;
  final String updatedAt;

  const HomeLoanType({
    required this.id,
    required this.name,
    required this.prefix,
    required this.ltvReduction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeLoanType.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeLoanType(
      id: _toString(json['id']),
      name: _toString(json['name']),
      prefix: _toString(json['prefix']),
      ltvReduction:
          _toDouble(json['ltvReduction']),
      createdAt:
          _toString(json['createdAt']),
      updatedAt:
          _toString(json['updatedAt']),
    );
  }
}

// ============================================================
// BORROWER REFERENCE
// ============================================================

class HomeBorrowerReference {
  final String id;
  final String relation;

  const HomeBorrowerReference({
    required this.id,
    required this.relation,
  });

  factory HomeBorrowerReference.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeBorrowerReference(
      id: _toString(json['id']),
      relation: _toString(json['relation']),
    );
  }
}

// ============================================================
// GUARANTOR REFERENCE
// ============================================================

class HomeGuarantorReference {
  final String id;
  final String relation;

  const HomeGuarantorReference({
    required this.id,
    required this.relation,
  });

  factory HomeGuarantorReference.fromJson(
    Map<String, dynamic> json,
  ) {
    return HomeGuarantorReference(
      id: _toString(json['id']),
      relation: _toString(json['relation']),
    );
  }
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

String _toString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final stringValue = value.toString();

  return stringValue.isEmpty ? null : stringValue;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }

  return 0.0;
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