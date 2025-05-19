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

    final trailers = (response['results'] as List)
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
        queryParameters: {'append_to_response': 'videos,credits,external_ids'},
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

  Future<Map<String, dynamic>> getWatchProviders(int tvId) async {
    print('=== TV WATCH PROVIDERS ===');
    print('Fetching watch providers for TV show ID: $tvId');
    try {
      final response = await _apiClient.get('/tv/$tvId/watch/providers');
      print('Raw watch providers response: $response');

      // Add detailed logging of the response structure
      if (response != null && response.isNotEmpty) {
        print('\nDetailed watch providers response structure:');
        print('Results: ${response['results']}');
        if (response['results'] != null) {
          final results = response['results'] as Map<String, dynamic>;
          print('\nAvailable regions: ${results.keys.join(', ')}');
          if (results.containsKey('US')) {
            final usData = results['US'];
            print('\nUS data structure:');
            print('Flatrate: ${usData['flatrate']}');
            print('Rent: ${usData['rent']}');
            print('Buy: ${usData['buy']}');
            print('Free: ${usData['free']}');
            print('Link: ${usData['link']}');
          }
        }
      }

      if (response == null || response.isEmpty) {
        print('Empty response received for watch providers');
        return {
          'results': {}
        }; // Return empty results structure instead of empty map
      }

      // Return the complete response structure
      return response;
    } catch (e) {
      print('Error fetching watch providers: $e');
      return {'results': {}}; // Return empty results structure on error
    }
  }

  /// Returns a list of popular TV shows filtered by genre IDs.
  Future<List<TvShow>> getPopularTvShowsByGenres(List<int> genreIds,
      {int page = 1}) async {
    final allShows = await getPopularTvShows(page: page);
    return allShows
        .where((show) => show.genreIds.any((id) => genreIds.contains(id)))
        .toList();
  }

  /// Returns a list of top-rated TV shows filtered by genre IDs.
  Future<List<TvShow>> getTopRatedTvShowsByGenres(List<int> genreIds,
      {int page = 1}) async {
    final allShows = await getTopRatedTvShows(page: page);
    return allShows
        .where((show) => show.genreIds.any((id) => genreIds.contains(id)))
        .toList();
  }
}
