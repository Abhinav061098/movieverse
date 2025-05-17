import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;

  // Add a getter for the Dio instance
  Dio get getDio => _dio;

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
          return status != null && status < 500;
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ),
    );

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) {
          print('Error Response: ${error.response}');
          print('Error Message: ${error.message}');
          print('Error Type: ${error.type}');
          print('Error Headers: ${error.response?.headers}');
          print('Error Request Headers: ${error.requestOptions.headers}');
          print('Error Request URL: ${error.requestOptions.uri}');
          return handler.next(error);
        },
        onResponse: (response, handler) {
          print('Response Status: ${response.statusCode}');
          print('Response Headers: ${response.headers}');
          print('Response Data: ${response.data}');
          return handler.next(response);
        },
        onRequest: (options, handler) {
          // Merge query parameters with the base parameters
          final Map<String, dynamic> mergedParams = {
            ...options.queryParameters,
            'api_key': ApiConstants.apiKey,
            'language': 'en-US',
          };
          options.queryParameters = mergedParams;

          print('Request URL: ${options.uri}');
          print('Request Headers: ${options.headers}');
          print('Request Parameters: ${options.queryParameters}');
          return handler.next(options);
        },
      ),
    );
  }

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
