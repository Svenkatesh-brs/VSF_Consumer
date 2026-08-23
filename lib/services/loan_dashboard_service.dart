import '../models/loan_dashboard_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class LoanDashboardService {
  final ApiService _apiService;

  LoanDashboardService({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ============================================================
  // GET LOAN BY ID
  //
  // ONE call for the whole Loan Dashboard feature:
  //
  //   GET /api/v1/consumer/loan/{loanId}
  //
  // The single response is parsed into the four domain models
  // (dashboard / details / transactions / EMI schedule) inside
  // LoanDashboardResponse.
  // ============================================================

  Future<LoanDashboardResponse> getLoanById(
    String loanId,
  ) async {
    final response = await _apiService.get(
      '${AppConstants.loanById}$loanId',
    );

    // ----------------------------------------------------------
    // RESPONSE VALIDATION
    // ----------------------------------------------------------

    if (response.data is! Map) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Invalid response received from server.',
      );
    }

    final parsed = LoanDashboardResponse.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );

    // ----------------------------------------------------------
    // success=false is returned to the provider so it can show
    // its own error state with the backend message, exactly like
    // the Home flow handles API failures.
    // ----------------------------------------------------------

    return parsed;
  }
}
