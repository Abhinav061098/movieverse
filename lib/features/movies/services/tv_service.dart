import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/tv_show.dart';
import '../models/tv_show_details.dart';
import '../models/movie_trailer.dart';
import '../models/genre.dart';
import '../models/season.dart';
import 'dart:developer' as developer;

class TvService {
  final ApiClient _apiClient;

  TvService(this._apiClient);

  Future<List<TvShow>> getPopularTvShows({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.popularTvShows,
      queryParameters: {'page': page},
    );
    return (response['results'] as List)
        .map((show) => TvShow.fromJson(show))
        .toList();
  }

  Future<List<TvShow>> getTopRatedTvShows({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.topRatedTvShows,
      queryParameters: {'page': page},
    );
    return (response['results'] as List)
        .map((show) => TvShow.fromJson(show))
        .toList();
  }

  Future<List<TvShow>> getAiringTodayTvShows({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.airingTodayTvShows,
      queryParameters: {'page': page},
    );
    return (response['results'] as List)
        .map((show) => TvShow.fromJson(show))
        .toList();
  }

  Future<List<TvShow>> getOnTheAirTvShows({int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.onTheAirTvShows,
      queryParameters: {'page': page},
    );
    return (response['results'] as List)
        .map((show) => TvShow.fromJson(show))
        .toList();
  }

  Future<List<MovieTrailer>> getTvShowTrailers(int tvId) async {
    final response = await _apiClient.get(
      ApiConstants.tvShowVideos.replaceFirst('{tv_id}', tvId.toString()),
    );

    final trailers =
        (response['results'] as List)
            .where(
              (video) =>
                  video['site'].toString().toLowerCase() == 'youtube' &&
                  video['type'].toString().toLowerCase() == 'trailer',
            )
            .map((trailer) => MovieTrailer.fromJson(trailer))
            .toList();

    trailers.sort(
      (a, b) => DateTime.parse(
        b.publishedAt,
      ).compareTo(DateTime.parse(a.publishedAt)),
    );
    return trailers;
  }

  Future<List<TvShow>> searchTvShows(String query, {int page = 1}) async {
    final response = await _apiClient.get(
      '/search/tv',
      queryParameters: {'query': query, 'page': page},
    );

    return (response['results'] as List)
        .map((show) => TvShow.fromJson(show))
        .toList();
  }

  Future<List<Genre>> getTvGenres() async {
    final response = await _apiClient.get('/genre/tv/list');

    return (response['genres'] as List)
        .map((genre) => Genre.fromJson(genre))
        .toList();
  }

  Future<List<Genre>> getGenres() async {
    final response = await _apiClient.get('/genre/tv/list');
    final results = response['genres'] as List;
    return results.map((genre) => Genre.fromJson(genre)).toList();
  }

  Future<TvShowDetails> fetchTvShowDetails(int tvId) async {
    try {
      final response = await _apiClient.get(
        '/tv/$tvId',
        queryParameters: {'append_to_response': 'videos,credits'},
      );

      // Log the seasons data for debugging
      developer.log('Seasons data: ${response['seasons']}', name: 'TvService');

      return TvShowDetails.fromJson(response);
    } catch (e) {
      developer.log('Error fetching TV show details: $e', name: 'TvService');
      rethrow;
    }
  }

  Future<Season> fetchSeasonDetails(int tvId, int seasonNumber) async {
    try {
      final response = await _apiClient.get('/tv/$tvId/season/$seasonNumber');

      // Log the season details for debugging
      developer.log('Season details: $response', name: 'TvService');

      return Season.fromJson(response);
    } catch (e) {
      developer.log('Error fetching season details: $e', name: 'TvService');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWatchProviders(int tvShowId) async {
    try {
      final response = await _apiClient.get('/tv/$tvShowId/watch/providers');

      // Get US results or fall back to first available region
      final results = response['results'] as Map<String, dynamic>;
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
}
