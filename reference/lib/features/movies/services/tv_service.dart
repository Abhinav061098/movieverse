import 'package:dio/dio.dart';
import '../../../core/api/api_constants.dart';
import '../models/tv_show.dart';
import '../models/tv_show_details.dart';
import '../models/movie_trailer.dart';
import '../models/genre.dart';
import '../models/season.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class TvService {
  final Dio _dio;
  static const int _maxRetries = 3;

  TvService(this._dio);

  Future<T> _retryOnFailure<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (attempts < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw Exception('All retry attempts failed');
  }

  Future<List<TvShow>> getPopularTvShows({int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };

        final response = await _dio.get(
          ApiConstants.popularTvShows,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          debugPrint('Invalid API response for popular TV shows');
          throw Exception('Invalid API response for popular TV shows');
        }

        final results = response.data['results'] as List;
        final shows = results
            .map((show) => TvShow.fromJson(show))
            .where((show) => genreId == null || show.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${shows.length} popular TV shows after genre filtering');
        return shows;
      } catch (e, stack) {
        debugPrint('Error in getPopularTvShows: $e\n$stack');
        throw Exception('Failed to load popular TV shows: $e');
      }
    });
  }

  Future<String?> getTvShowCertification(int tvId) async {
    try {
      final response = await _dio.get(
        '/tv/$tvId/content_ratings',
        queryParameters: {'api_key': ApiConstants.apiKey},
      );

      final results = response.data['results'] as List;

      // First try to find US rating
      final usRating = results.firstWhere(
        (rating) => rating['iso_3166_1'] == 'US',
        orElse: () => null,
      );

      if (usRating != null) {
        return usRating['rating'];
      }

      // If no US rating, return first available rating
      if (results.isNotEmpty) {
        return results.first['rating'];
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching TV certification: $e');
      return null;
    }
  }

  Future<List<TvShow>> getTopRatedTvShows({int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };

        final response = await _dio.get(
          ApiConstants.topRatedTvShows,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          debugPrint('Invalid API response for top rated TV shows');
          throw Exception('Invalid API response for top rated TV shows');
        }

        final results = response.data['results'] as List;
        final shows = results
            .map((show) => TvShow.fromJson(show))
            .where((show) => genreId == null || show.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${shows.length} top rated TV shows after genre filtering');
        return shows;
      } catch (e) {
        debugPrint('Error in getTopRatedTvShows: $e');
        throw Exception('Failed to load top rated TV shows: $e');
      }
    });
  }

  Future<List<TvShow>> getAiringTodayTvShows(
      {int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };

        final response = await _dio.get(
          ApiConstants.airingTodayTvShows,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          throw Exception('Invalid API response for airing today TV shows');
        }

        final results = response.data['results'] as List;
        final shows = results
            .map((show) => TvShow.fromJson(show))
            .where((show) => genreId == null || show.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${shows.length} airing today TV shows after genre filtering');
        return shows;
      } catch (e) {
        throw Exception('Failed to load airing today TV shows: $e');
      }
    });
  }

  Future<List<TvShow>> getOnTheAirTvShows({int? genreId, int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final Map<String, dynamic> params = {
          'page': page,
        };

        final response = await _dio.get(
          ApiConstants.onTheAirTvShows,
          queryParameters: params,
        );

        if (response.data == null || response.data['results'] == null) {
          debugPrint('Invalid API response for on the air TV shows');
          throw Exception('Invalid API response for on the air TV shows');
        }

        final results = response.data['results'] as List;
        final shows = results
            .map((show) => TvShow.fromJson(show))
            .where((show) => genreId == null || show.genreIds.contains(genreId))
            .toList();
        debugPrint(
            'Retrieved ${shows.length} on the air TV shows after genre filtering');
        return shows;
      } catch (e) {
        debugPrint('Error in getOnTheAirTvShows: $e');
        throw Exception('Failed to load on the air TV shows: $e');
      }
    });
  }

  Future<List<MovieTrailer>> getTvShowTrailers(int tvId) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get('/tv/$tvId/videos');

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to load TV show trailers: ${response.statusCode}');
        }

        final trailers = (response.data['results'] as List)
            .where(
                (item) => item['type'] == 'Trailer' || item['type'] == 'Teaser')
            .map((item) => MovieTrailer.fromJson(item))
            .toList();

        trailers.sort((a, b) {
          if (a.type == 'Trailer' && b.type != 'Trailer') {
            return -1;
          } else if (a.type != 'Trailer' && b.type == 'Trailer') {
            return 1;
          } else {
            return 0;
          }
        });

        return trailers;
      } catch (e, stack) {
        print('Error in getTvShowTrailers: $e\n$stack');
        throw Exception('Failed to load TV show trailers: $e');
      }
    });
  }

  Future<List<TvShow>> searchTvShows(String query, {int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get(
          '/search/tv',
          queryParameters: {'query': query, 'page': page},
        );

        return (response.data['results'] as List)
            .map((show) => TvShow.fromJson(show))
            .toList();
      } catch (e, stack) {
        print('Error in searchTvShows: $e\n$stack');
        throw Exception('Failed to search TV shows: $e');
      }
    });
  }

  Future<List<Genre>> getTvGenres() async {
    return _retryOnFailure(() async {
      try {
        print('Fetching TV genres from ${ApiConstants.tvGenres}');

        final response = await _dio.get(
          ApiConstants.tvGenres,
          options: Options(
            validateStatus: (status) {
              return status != null && status >= 200 && status < 300;
            },
          ),
        );

        if (response.data == null || response.data['genres'] == null) {
          throw Exception('Invalid API response for TV genres');
        }

        final genres = (response.data['genres'] as List)
            .map((genre) => Genre.fromJson(genre))
            .toList();

        return genres;
      } catch (e, stack) {
        print('Error in getTvGenres: $e\n$stack');
        throw Exception('Failed to load TV genres: $e');
      }
    });
  }

  Future<TvShowDetails> fetchTvShowDetails(int tvId) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get(
          '/tv/$tvId',
          queryParameters: {'append_to_response': 'videos,credits'},
        );
        return TvShowDetails.fromJson(response.data);
      } catch (e, stack) {
        developer.log('Error in fetchTvShowDetails: $e\n$stack');
        throw Exception('Failed to fetch TV show details: $e');
      }
    });
  }

  Future<Season> fetchSeasonDetails(int tvId, int seasonNumber) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get('/tv/$tvId/season/$seasonNumber');
        return Season.fromJson(response.data);
      } catch (e, stack) {
        developer.log('Error in fetchSeasonDetails: $e\n$stack');
        throw Exception('Failed to fetch season details: $e');
      }
    });
  }

  Future<Map<String, dynamic>> getWatchProviders(int tvId) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get('/tv/$tvId/watch/providers');

        final results = response.data['results'] as Map<String, dynamic>;
        if (results.containsKey('US')) {
          return results['US'] as Map<String, dynamic>;
        } else if (results.isNotEmpty) {
          return results.values.first as Map<String, dynamic>;
        }
        return {};
      } catch (e, stack) {
        print('Error in getWatchProviders: $e\n$stack');
        throw Exception('Failed to fetch watch providers: $e');
      }
    });
  }

  Future<List<TvShow>> getTvShowsByGenre(int genreId, {int page = 1}) async {
    return _retryOnFailure(() async {
      try {
        final response = await _dio.get(
          '/discover/tv',
          queryParameters: {
            'with_genres': genreId.toString(),
            'page': page,
            'sort_by': 'popularity.desc',
          },
        );

        if (response.data == null || response.data['results'] == null) {
          throw Exception('Invalid API response for TV shows by genre');
        }

        final results = response.data['results'] as List;
        final shows = results
            .map((show) => TvShow.fromJson(show))
            .where((show) => show.genreIds.contains(genreId))
            .toList();

        debugPrint('Retrieved ${shows.length} TV shows for genre $genreId');
        return shows;
      } catch (e, stack) {
        debugPrint('Error in getTvShowsByGenre: $e\n$stack');
        throw Exception('Failed to load TV shows by genre: $e');
      }
    });
  }

  Future<List<TvShow>> getTrendingTvShows({int? genreId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (genreId != null) {
        params['with_genres'] = genreId.toString();
      }

      final response = await _dio.get(
        '/trending/tv/day',
        queryParameters: params,
      );

      final results = response.data['results'] as List;
      final shows = results.map((show) => TvShow.fromJson(show)).toList();

      debugPrint('Retrieved ${shows.length} trending TV shows');
      return shows;
    } catch (e) {
      debugPrint('Error in getTrendingTvShows: $e');
      throw Exception('Failed to fetch trending TV shows: $e');
    }
  }
}
