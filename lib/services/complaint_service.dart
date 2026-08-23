import '../models/complaint_model.dart';
import 'api_service.dart';

class ComplaintService {
  ComplaintService({
    required ApiService apiService,
  }) : _apiService = apiService;

  final ApiService _apiService;

  // ============================================================
  // ENDPOINTS
  // ============================================================

  static const String _createComplaintEndpoint =
      '/api/v1/compliant/create';

  static const String _listComplaintsEndpoint =
      '/api/v1/compliant/list';

  // ============================================================
  // CREATE COMPLAINT
  // ============================================================

  Future<ComplaintCreateResponse> createComplaint(
    ComplaintCreateRequest request,
  ) async {
    final response = await _apiService.post(
      _createComplaintEndpoint,
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ComplaintCreateResponse.fromJson(data);
    }

    if (data is Map) {
      return ComplaintCreateResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw Exception(
      'Invalid complaint create response.',
    );
  }

  // ============================================================
  // GET COMPLAINTS BY STATUS
  // ============================================================

  Future<ComplaintListResponse> getComplaints(
    ComplaintListRequest request,
  ) async {
    final response = await _apiService.post(
      _listComplaintsEndpoint,
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ComplaintListResponse.fromJson(data);
    }

    if (data is Map) {
      return ComplaintListResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw Exception(
      'Invalid complaint list response.',
    );
  }
}