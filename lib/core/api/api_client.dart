import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:collection';

class ApiClient {
  late final Dio _dio;
  final int _maxRetries = 2;
  final Duration _retryDelay = const Duration(milliseconds: 200);
  final _requestQueue = StreamController<Future<dynamic>>.broadcast();
  final _maxConcurrentRequests = 2;
  int _currentRequests = 0;

  final _cache = LinkedHashMap<String, dynamic>();
  final Duration _cacheDuration = const Duration(minutes: 5);

  final _failedRequests = HashSet<String>();

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
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        logPrint: (object) => developer.log(object.toString(), name: 'API'),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cacheKey = _getCacheKey(options);

          if (_failedRequests.contains(cacheKey)) {
            developer.log('Skipping previously failed request: ${options.path}',
                name: 'API');
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Request previously failed',
                type: DioExceptionType.unknown,
              ),
            );
          }

          if (_cache.containsKey(cacheKey)) {
            final cachedData = _cache[cacheKey];
            if (cachedData != null && !_isCacheExpired(cachedData)) {
              developer.log('Cache hit for: ${options.path}', name: 'API');
              return handler.resolve(Response(
                requestOptions: options,
                data: cachedData['data'],
                statusCode: 200,
              ));
            }
          }

          if (_currentRequests >= _maxConcurrentRequests) {
            developer.log('Request queued: ${options.path}', name: 'API');
            await _waitForSlot();
          }
          _currentRequests++;
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _currentRequests--;
          if (response.statusCode == 200) {
            final cacheKey = _getCacheKey(response.requestOptions);
            _cache[cacheKey] = {
              'data': response.data,
              'timestamp': DateTime.now(),
            };
            _failedRequests.remove(cacheKey);
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          _currentRequests--;
          final cacheKey = _getCacheKey(error.requestOptions);

          if (_shouldRetry(error)) {
            if (!_failedRequests.contains(cacheKey)) {
              return handler.resolve(await _retry(error.requestOptions));
            }
          }

          _failedRequests.add(cacheKey);
          return handler.next(error);
        },
      ),
    );

    _processQueue();
  }

  String _getCacheKey(RequestOptions options) {
    return '${options.path}?${options.queryParameters}';
  }

  bool _isCacheExpired(Map<String, dynamic> cachedData) {
    final timestamp = cachedData['timestamp'] as DateTime;
    return DateTime.now().difference(timestamp) > _cacheDuration;
  }

  Future<List<T>> batchGet<T>({
    required List<String> paths,
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
    bool useCache = true,
  }) async {
    final results = <T>[];
    final errors = <String>[];
    final batchSize = 3;

    for (var i = 0; i < paths.length; i += batchSize) {
      final batch = paths.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((path) =>
            get(path, queryParameters: queryParameters).then((response) {
              if (response == null || (response is Map && response.isEmpty)) {
                return null;
              }
              return fromJson(response);
            }).catchError((e) {
              developer.log('Error in batch request for $path: $e',
                  name: 'API');
              errors.add('$path: $e');
              return null;
            })),
      );

      results.addAll(batchResults.whereType<T>());

      if (i + batchSize < paths.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (errors.isNotEmpty) {
      developer.log(
        'Batch request completed with ${errors.length} errors',
        name: 'API',
      );
    }

    return results;
  }

  Future<void> _waitForSlot() async {
    final completer = Completer<void>();
    _requestQueue.add(Future.value().then((_) {
      completer.complete();
    }));
    return completer.future;
  }

  void _processQueue() {
    _requestQueue.stream.listen((request) async {
      try {
        await request;
      } catch (e) {
        developer.log(
          'Error processing queued request: $e',
          name: 'API',
          error: e,
        );
      }
    });
  }

  bool _shouldRetry(DioException error) {
    final shouldRetry = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError;

    developer.log(
      'Should retry: $shouldRetry for error type: ${error.type}',
      name: 'API',
    );

    return shouldRetry;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        developer.log(
          'Retry attempt ${retryCount + 1} of $_maxRetries',
          name: 'API',
        );

        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          throw DioException(
            requestOptions: requestOptions,
            error: 'No internet connection',
            type: DioExceptionType.connectionError,
          );
        }

        final response = await _dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        return response;
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          throw DioException(
            requestOptions: requestOptions,
            error: 'Failed after $_maxRetries attempts: $e',
          );
        }
        await Future.delayed(_retryDelay);
      }
    }
    throw DioException(
      requestOptions: requestOptions,
      error: 'Failed after $_maxRetries attempts',
    );
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      developer.log(
        'Connectivity check result: $connectivityResult',
        name: 'API',
      );
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      developer.log(
        'Connectivity check failed: $e',
        name: 'API',
        error: e,
      );
      return false;
    }
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
        if (error.message?.contains('No internet connection') ?? false) {
          return ApiException('No internet connection', 503);
        }
        return ApiException('Connection error', 503);
      default:
        return ApiException(error.message ?? 'Unknown error occurred', 500);
    }
  }

  @override
  void dispose() {
    _requestQueue.close();
  }
}
