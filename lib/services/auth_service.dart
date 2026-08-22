import '../models/request_otp_model.dart';
import '../models/verify_otp_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ============================================================
  // REQUEST OTP
  // ============================================================

  Future<RequestOtpResponse> requestOtp(
    RequestOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.requestOtp,
      data: request.toJson(),
    );

    return RequestOtpResponse.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<VerifyOtpResponse> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.verifyOtp,
      data: request.toJson(),
    );

    return VerifyOtpResponse.fromJson(
      Map<String, dynamic>.from(
        response.data,
      ),
    );
  }
}