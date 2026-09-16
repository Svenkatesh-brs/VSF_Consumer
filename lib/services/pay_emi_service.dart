import 'package:dio/dio.dart';

import '../models/pay_emi_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class PayEmiService {
  final ApiService _apiService;

  PayEmiService({
    required ApiService apiService,
    // ignore: prefer_initializing_formals
  }) : _apiService = apiService;

  // ============================================================
  // PAYMENT INFORMATION
  // ============================================================

  Future<PayEmiModel> getPaymentInfo() async {
    final response = await _apiService.get(
      AppConstants.company,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw ApiException(message: 'Unable to load payment details');
    }

    final message = responseData['message']?.toString() ?? '';
    final error = responseData['error']?.toString() ?? '';

    final success = responseData['success'] as bool? ?? false;

    if (!success) {
      throw ApiException(
        message: message.isNotEmpty
            ? message
            : (error.isNotEmpty ? error : 'Unable to load payment details'),
      );
    }

    final companyData = responseData['data'];

    if (companyData is! Map<String, dynamic>) {
      throw ApiException(
        message: message.isNotEmpty
            ? message
            : (error.isNotEmpty ? error : 'Payment information not found'),
      );
    }

    return PayEmiModel.fromJson(companyData);
  }

  // ============================================================
  // QR IMAGE
  // ============================================================

  Future<List<int>> getQrImage(String did) async {
    if (did.trim().isEmpty) {
      throw Exception('QR image file is not available');
    }

    final response = await _apiService.get(
      '${AppConstants.consumerMedia}$did',
      responseType: ResponseType.bytes,
    );

    final data = response.data;

    if (data is List<int> && data.isNotEmpty) {
      return data;
    }

    throw Exception('QR image could not be loaded');
  }
}