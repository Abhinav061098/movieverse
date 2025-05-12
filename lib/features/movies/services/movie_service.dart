import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/movie.dart';
import '../models/movie_trailer.dart';
import '../models/movie_details.dart';
import '../models/credits.dart';
import '../models/genre.dart';

class MovieService {
  final Dio _dio;
  final String _baseUrl = ApiConstants.baseUrl;
  final String _apiKey = ApiConstants.apiKey;
  final ApiClient _apiClient;
  final int _maxRetries = 3;

  MovieService(this._apiClient) : _dio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError) {
            // Connection related errors will be handled by the retry mechanism
            handler.next(e);
          } else {
            debugPrint('DioException: ${e.message}');
            handler.next(e);
          }
        },
      ),
    );

    // Configure Dio timeouts
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 5);
  }

  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        retryCount++;
        debugPrint('API request failed (attempt $retryCount): ${e.message}');

        if (retryCount >= _maxRetries) {
          throw Exception('Failed after $retryCount attempts: ${e.message}');
        }

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        }

        rethrow;
      }
    }
    throw Exception('Failed after $retryCount attempts');
  }

  Future<List<Movie>> getTrendingMovies() async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/trending/movie/day',
        queryParameters: {'api_key': _apiKey},
      );

      final results = response.data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    });
  }

  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/movie/popular',
        queryParameters: {'api_key': _apiKey, 'page': page},
      );

      final results = response.data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    });
  }

  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/movie/top_rated',
        queryParameters: {'api_key': _apiKey, 'page': page},
      );

      final results = response.data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    });
  }

  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/movie/upcoming',
        queryParameters: {'api_key': _apiKey, 'page': page},
      );

      final results = response.data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    });
  }

  Future<Movie> getMovieDetails(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get(
        '${ApiConstants.movieDetails}$movieId',
      );
      return Movie.fromJson(response);
    });
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    return _retryRequest(() async {
      final response = await _apiClient.get(
        ApiConstants.searchMovie,
        queryParameters: {'query': query, 'page': page},
      );
      return (response['results'] as List)
          .map((movie) => Movie.fromJson(movie))
          .toList();
    });
  }

  Future<List<MovieTrailer>> getMovieTrailers(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get(
        ApiConstants.movieVideos.replaceFirst('{movie_id}', movieId.toString()),
      );

      final trailers = (response['results'] as List)
          .where(
            (video) =>
                video['site'].toString().toLowerCase() == 'youtube' &&
                video['type'].toString().toLowerCase() == 'trailer',
          )
          .map((trailer) => MovieTrailer.fromJson(trailer))
          .toList();

      // Sort by date to get latest trailers first
      trailers.sort(
        (a, b) => DateTime.parse(
          b.publishedAt,
        ).compareTo(DateTime.parse(a.publishedAt)),
      );

      return trailers;
    });
  }

  Future<List<MovieTrailer>> getLatestTrailers() async {
    final movies = await getUpcomingMovies();
    List<MovieTrailer> allTrailers = [];

    for (var movie in movies.take(5)) {
      // Get trailers for first 5 upcoming movies
      try {
        final trailers = await getMovieTrailers(movie.id);
        if (trailers.isNotEmpty) {
          allTrailers.add(trailers.first); // Add the latest trailer
        }
      } catch (e) {
        print('Error fetching trailer for movie ${movie.id}: $e');
      }
    }

    return allTrailers;
  }

  Future<MovieDetails> fetchMovieDetails(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get(
        '/movie/$movieId',
        queryParameters: {'append_to_response': 'videos,credits,release_dates'},
      );
      return MovieDetails.fromJson(response);
    });
  }

  Future<Credits> getMovieCredits(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get('/movie/$movieId/credits');
      return Credits.fromJson(response);
    });
  }

  Future<String?> getMovieCertification(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get('/movie/$movieId/release_dates');
      final results = response['results'] as List;
      final usRelease = results.firstWhere(
        (release) => release['iso_3166_1'] == 'US',
        orElse: () => null,
      );
      if (usRelease != null) {
        final releases = usRelease['release_dates'] as List;
        final certification = releases.firstWhere(
          (release) => release['certification']?.isNotEmpty ?? false,
          orElse: () => null,
        );
        return certification?['certification'];
      }
      return null;
    });
  }

  Future<MovieDetails> getMovieOfTheDay() async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/movie/top_rated',
        queryParameters: {'api_key': _apiKey, 'vote_average.gte': 7.0},
      );

      final results = response.data['results'] as List;
      final filteredMovies = results
          .where(
            (movie) => (movie['vote_average'] as num).toDouble() >= 7.0,
          )
          .toList();

      if (filteredMovies.isEmpty) {
        throw Exception('No movies found matching criteria');
      }

      final random = DateTime.now().day % filteredMovies.length;
      final selectedMovie = filteredMovies[random];

      return await fetchMovieDetails(selectedMovie['id']);
    });
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    return _retryRequest(() async {
      final response = await _apiClient.get('/movie/$movieId/watch/providers');

      // Get US results or fall back to first available region
      final results = response['results'] as Map<String, dynamic>;
      if (results.containsKey('US')) {
        return results['US'] as Map<String, dynamic>;
      } else if (results.isNotEmpty) {
        return results.values.first as Map<String, dynamic>;
      }
      return {};
    });
  }

  Future<List<Genre>> getGenres() async {
    return _retryRequest(() async {
      final response = await _dio.get(
        '$_baseUrl/genre/movie/list',
        queryParameters: {'api_key': _apiKey},
      );
      final results = response.data['genres'] as List;
      return results.map((genre) => Genre.fromJson(genre)).toList();
    });
  }
}
