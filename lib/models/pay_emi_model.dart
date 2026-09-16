class PayEmiFile {
  final String name;
  final String upiId;
  final String did;

  const PayEmiFile({
    this.name = '',
    this.upiId = '',
    this.did = '',
  });

  factory PayEmiFile.fromJson(Map<String, dynamic> json) {
    return PayEmiFile(
      name: json['name']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
      did: json['did']?.toString() ?? '',
    );
  }
}

class PayEmiModel {
  final List<String> contactNumbers;
  final List<String> paymentNumbers;
  final List<String> upiIds;
  final List<PayEmiFile> files;

  const PayEmiModel({
    required this.contactNumbers,
    required this.paymentNumbers,
    required this.upiIds,
    required this.files,
  });

  factory PayEmiModel.fromJson(Map<String, dynamic> json) {
    final fileItems = json['file'];

    return PayEmiModel(
      contactNumbers: (json['contactNumbers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      paymentNumbers: (json['paymentNumbers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      upiIds: (json['upiIds'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      files: (fileItems is List<dynamic> ? fileItems : <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((item) => PayEmiFile.fromJson(item))
          .toList(),
    );
  }
}