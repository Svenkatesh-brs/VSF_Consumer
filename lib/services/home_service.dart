import '../models/home_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class HomeService {
  final ApiService _apiService;

  HomeService({
    required ApiService apiService,
  }) : _apiService = apiService;

  // ============================================================
  // GET HOME DATA
  // ============================================================

  Future<HomeResponse> getHomeData(
    HomeRequest request,
  ) async {
    final response = await _apiService.post(
      AppConstants.home,
      data: request.toJson(),
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

    return HomeResponse.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }
}