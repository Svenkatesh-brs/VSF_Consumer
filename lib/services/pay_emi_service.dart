import 'package:dio/dio.dart';

import '../models/pay_emi_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class PayEmiService {
  final ApiService _apiService;

  PayEmiService({
    required ApiService apiService,
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
      throw Exception('Invalid payment information response');
    }

    final companyData = responseData['data'];

    if (companyData is! Map<String, dynamic>) {
      throw Exception('Payment information not found');
    }

    return PayEmiModel.fromJson(companyData);
  }

  // ============================================================
  // QR IMAGE
  // ============================================================

  Future<List<int>> getQrImage(String fileId) async {
    if (fileId.trim().isEmpty) {
      throw Exception('QR image file is not available');
    }

    final response = await _apiService.get(
      '${AppConstants.consumerMedia}$fileId',
      responseType: ResponseType.bytes,
    );

    final data = response.data;

    if (data is List<int> && data.isNotEmpty) {
      return data;
    }

    throw Exception('QR image could not be loaded');
  }
}