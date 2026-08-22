class VerifyOtpRequest {
  final String countryCode;
  final String phone;
  final String otp;

  const VerifyOtpRequest({
    required this.countryCode,
    required this.phone,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'phone': phone,
      'otp': otp,
    };
  }
}

// ================================================================
// VERIFY OTP RESPONSE
// ================================================================

class VerifyOtpResponse {
  final String message;
  final bool success;
  final String? token;

  const VerifyOtpResponse({
    required this.message,
    required this.success,
    this.token,
  });

  factory VerifyOtpResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerifyOtpResponse(
      message: json['message']?.toString() ?? '',
      success: json['success'] == true,
      token: json['token']?.toString(),
    );
  }
}