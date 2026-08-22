import 'package:dio/dio.dart';

class ApiService {
  late final Dio _dio;

  ApiService({
    required String baseUrl,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 15,
        ),
        receiveTimeout: const Duration(
          seconds: 15,
        ),
        sendTimeout: const Duration(
          seconds: 15,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ============================================================
  // GET
  // ============================================================

  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Response<dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<Response<dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<Response<dynamic>> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      return await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ),
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  Exception _handleDioException(
    DioException exception,
  ) {
    if (exception.response != null) {
      final statusCode =
          exception.response?.statusCode;

      final responseData =
          exception.response?.data;

      String message =
          'Something went wrong';

      if (responseData is Map) {
        if (responseData['message'] != null) {
          message =
              responseData['message'].toString();
        } else if (responseData['error'] != null) {
          message =
              responseData['error'].toString();
        }
      }

      return ApiException(
        statusCode: statusCode,
        message: message,
      );
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Connection timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message:
              'Unable to connect to the server.',
        );

      case DioExceptionType.cancel:
        return ApiException(
          message:
              'Request was cancelled.',
        );

      default:
        return ApiException(
          message:
              'Something went wrong. Please try again.',
        );
    }
  }
}

// ================================================================
// API EXCEPTION
// ================================================================

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({
    this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return message;
  }
}