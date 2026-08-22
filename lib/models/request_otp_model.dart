class RequestOtpRequest {
  final String countryCode;
  final String phone;

  const RequestOtpRequest({
    required this.countryCode,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'phone': phone,
    };
  }
}

class RequestOtpResponse {
  final dynamic data;
  final String message;
  final bool success;

  const RequestOtpResponse({
    this.data,
    required this.message,
    required this.success,
  });

  factory RequestOtpResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RequestOtpResponse(
      data: json['data'],
      message: json['message']?.toString() ?? '',
      success: json['success'] == true,
    );
  }
}