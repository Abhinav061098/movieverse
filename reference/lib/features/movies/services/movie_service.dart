import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_constants.dart';
import '../models/movie.dart';
import '../models/movie_trailer.dart';
import '../models/genre.dart';
import '../models/movie_details.dart';
import '../models/credits.dart';

class MovieService {
  late final Dio _dio;

  MovieService([dynamic _]) {
    // Changed to accept any argument but ignore it
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.accessToken}',
          'accept': 'application/json',
        },
        queryParameters: {'api_key': ApiConstants.apiKey, 'language': 'en-US'},
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
      ),
    );
  }

  Future<List<Genre>> getGenres() async {
    try {
      final response = await _dio.get('/genre/movie/list');
      final results = response.data['genres'] as List;
      return results.map((genre) => Genre.fromJson(genre)).toList();
    } catch (e) {
      throw Exception('Failed to fetch movie genres: $e');
    }
  }

  Future<List<Movie>> getTrendingMovies({int? genreId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (genreId != null) {
        params['with_genres'] = genreId.toString();
      }

      final response = await _dio.get(
        '/trending/movie/day',
        queryParameters: params,
      );

      final results = response.data['results'] as List;
      return results.map((movie) => Movie.fromJson(movie)).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending movies: $e');
    }
  }

  Future<List<Movie>> getPopularMovies({int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };
        if (genreId != null) {
          params['with_genres'] = genreId.toString();
          debugPrint(
              'Getting popular movies with genre: $genreId, page: $page');
        }

        final response = await _dio.get(
          ApiConstants.popularMovies,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          debugPrint('Invalid API response for popular movies');
          throw Exception('Invalid API response for popular movies');
        }

        final results = response.data['results'] as List;
        final movies = results
            .map((movie) => Movie.fromJson(movie))
            .where(
                (movie) => genreId == null || movie.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${movies.length} popular movies after genre filtering');
        return movies;
      } catch (e, stack) {
        debugPrint('Error in getPopularMovies: $e\n$stack');
        throw Exception('Failed to load popular movies: $e');
      }
    });
  }

  Future<List<Movie>> getTopRatedMovies({int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };
        if (genreId != null) {
          params['with_genres'] = genreId.toString();
          debugPrint(
              'Getting top rated movies with genre: $genreId, page: $page');
        }

        final response = await _dio.get(
          ApiConstants.topRatedMovies,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          debugPrint('Invalid API response for top rated movies');
          throw Exception('Invalid API response for top rated movies');
        }

        final results = response.data['results'] as List;
        final movies = results
            .map((movie) => Movie.fromJson(movie))
            .where(
                (movie) => genreId == null || movie.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${movies.length} top rated movies after genre filtering');
        return movies;
      } catch (e, stack) {
        debugPrint('Error in getTopRatedMovies: $e\n$stack');
        throw Exception('Failed to load top rated movies: $e');
      }
    });
  }

  Future<List<Movie>> getUpcomingMovies({int? genreId, int page = 1}) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
      };
      if (genreId != null) {
        params['with_genres'] = genreId.toString();
      }

      final response = await _dio.get(
        ApiConstants.upcomingMovies,
        queryParameters: params,
      );

      final results = response.data['results'] as List;
      final movies = results
          .map((movie) => Movie.fromJson(movie))
          .where((movie) => genreId == null || movie.genreIds.contains(genreId))
          .toList();
      debugPrint(
          'Retrieved ${movies.length} upcoming movies after genre filtering');
      return movies;
    } catch (e) {
      print('Error fetching upcoming movies: $e');
      throw Exception('Failed to fetch upcoming movies: $e');
    }
  }

  Future<Movie> getMovieDetails(int movieId) async {
    final response = await _dio.get('/movie/$movieId');
    return Movie.fromJson(response.data);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final response = await _dio.get(
      '/search/movie',
      queryParameters: {'query': query, 'page': page},
    );
    return (response.data['results'] as List)
        .map((movie) => Movie.fromJson(movie))
        .toList();
  }

  Future<List<MovieTrailer>> getMovieTrailers(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId/videos',
    );

    final trailers = (response.data['results'] as List)
        .where(
          (video) =>
              video['site'].toString().toLowerCase() == 'youtube' &&
              video['type'].toString().toLowerCase() == 'trailer',
        )
        .map((trailer) => MovieTrailer.fromJson(trailer))
        .toList();

    trailers.sort(
      (a, b) => DateTime.parse(b.publishedAt)
          .compareTo(DateTime.parse(a.publishedAt)),
    );

    return trailers;
  }

  Future<List<MovieTrailer>> getLatestTrailers() async {
    final movies = await getUpcomingMovies();
    List<MovieTrailer> allTrailers = [];

    for (var movie in movies.take(5)) {
      try {
        final trailers = await getMovieTrailers(movie.id);
        if (trailers.isNotEmpty) {
          allTrailers.add(trailers.first);
        }
      } catch (e) {
        print('Error fetching trailer for movie ${movie.id}: $e');
      }
    }

    return allTrailers;
  }

  Future<List<Genre>> getMovieGenres() async {
    final response = await _dio.get('/genre/movie/list');
    return (response.data['genres'] as List)
        .map((genre) => Genre.fromJson(genre))
        .toList();
  }

  Future<MovieDetails> fetchMovieDetails(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId',
      queryParameters: {'append_to_response': 'videos,credits,release_dates'},
    );
    return MovieDetails.fromJson(response.data);
  }

  Future<Credits> getMovieCredits(int movieId) async {
    final response = await _dio.get('/movie/$movieId/credits');
    return Credits.fromJson(response.data);
  }

  Future<String?> getMovieCertification(int movieId) async {
    final response = await _dio.get('/movie/$movieId/release_dates');
    final results = response.data['results'] as List;
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
  }

  Future<MovieDetails> getMovieOfTheDay() async {
    try {
      final response = await _dio.get(
        '/movie/top_rated',
        queryParameters: {'vote_average.gte': 7.0},
      );

      final results = response.data['results'] as List;
      final filteredMovies = results
          .where((movie) => (movie['vote_average'] as num).toDouble() >= 7.0)
          .toList();

      final random = DateTime.now().day % filteredMovies.length;
      final selectedMovie = filteredMovies[random];

      return await fetchMovieDetails(selectedMovie['id']);
    } catch (e) {
      throw Exception('Failed to fetch movie of the day: $e');
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    try {
      final response = await _dio.get('/movie/$movieId/watch/providers');

      final results = response.data['results'] as Map<String, dynamic>;
      if (results.containsKey('US')) {
        return results['US'] as Map<String, dynamic>;
      } else if (results.isNotEmpty) {
        return results.values.first as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error fetching watch providers: $e');
      return {};
    }
  }

  Future<List<Movie>> getMoviesByGenre(int genreId, {int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: {
            'with_genres': genreId.toString(),
            'page': page,
            'sort_by': 'popularity.desc',
          },
        );

        if (response.data == null || response.data['results'] == null) {
          throw Exception('Invalid API response for movies by genre');
        }

        final results = response.data['results'] as List;
        final movies = results
            .map((movie) => Movie.fromJson(movie))
            .where((movie) => movie.genreIds.contains(genreId))
            .toList();

        debugPrint('Retrieved ${movies.length} movies for genre $genreId');
        return movies;
      } catch (e, stack) {
        debugPrint('Error in getMoviesByGenre: $e\n$stack');
        throw Exception('Failed to load movies by genre: $e');
      }
    });
  }

  Future<T> _retryOnFailure<T>(Future<T> Function() action) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        return await action();
      } catch (e) {
        retryCount++;
        debugPrint('Retrying... Attempt $retryCount');
        if (retryCount == 3) rethrow;
      }
    }
    throw Exception('Failed after 3 retries');
  }
}
