import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ));

  Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Try to reach a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<Response> get(String url,
      {Map<String, dynamic>? queryParameters}) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      return await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw DioException(
          requestOptions: e.requestOptions,
          error: 'Connection timeout. Please check your internet connection.',
          type: e.type,
        );
      }
      rethrow;
    }
  }

  Future<Response> post(String url,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (!await isConnected()) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      return await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw DioException(
          requestOptions: e.requestOptions,
          error: 'Connection timeout. Please check your internet connection.',
          type: e.type,
        );
      }
      rethrow;
    }
  }
}
