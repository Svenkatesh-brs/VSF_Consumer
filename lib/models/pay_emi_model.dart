class PayEmiFile {
  final String name;
  final String upiId;
  final String paymentNumber;
  final String did;

  const PayEmiFile({
    this.name = '',
    this.upiId = '',
    this.paymentNumber = '',
    this.did = '',
  });

  factory PayEmiFile.fromJson(Map<String, dynamic> json) {
    return PayEmiFile(
      name: json['name']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
      paymentNumber: json['paymentNumber']?.toString() ?? '',
      did: json['did']?.toString() ?? '',
    );
  }
}

class PayEmiModel {
  final List<String> contactNumbers;
  final List<PayEmiFile> files;

  const PayEmiModel({
    this.contactNumbers = const [],
    this.files = const [],
  });

  factory PayEmiModel.fromJson(Map<String, dynamic> json) {
    final fileItems = json['file'];

    return PayEmiModel(
      contactNumbers: (json['contactNumbers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      files: (fileItems is List<dynamic> ? fileItems : <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map((item) => PayEmiFile.fromJson(item))
          .toList(),
    );
  }
}