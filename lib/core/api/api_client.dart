import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.accessToken}',
          'accept': 'application/json',
        },
        queryParameters: {'api_key': ApiConstants.apiKey, 'language': 'en-US'},
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
      ),
    );

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          print('Error Response: ${error.response}');
          return handler.next(error);
        },
        onResponse: (response, handler) {
          print('Response: ${response.data}');
          return handler.next(response);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    switch (response.statusCode) {
      case 200:
        return response.data;
      case 400:
        throw ApiException('Bad request', response.statusCode);
      case 401:
        throw ApiException('Unauthorized', response.statusCode);
      case 404:
        throw ApiException('Not found', response.statusCode);
      default:
        throw ApiException(
          response.statusMessage ?? 'Unknown error occurred',
          response.statusCode,
        );
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout', 408);
      case DioExceptionType.connectionError:
        return ApiException('No internet connection', 503);
      default:
        return ApiException(error.message ?? 'Unknown error occurred', 500);
    }
  }
}
