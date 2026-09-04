class PayEmiModel {
  final String id;
  final String name;
  final String alias;
  final List<String> paymentNumbers;
  final List<String> upiIds;
  final List<String> files;

  const PayEmiModel({
    required this.id,
    required this.name,
    required this.alias,
    required this.paymentNumbers,
    required this.upiIds,
    required this.files,
  });

  factory PayEmiModel.fromJson(Map<String, dynamic> json) {
    return PayEmiModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      paymentNumbers: (json['paymentNumbers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      upiIds: (json['upiIds'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      files: (json['file'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}