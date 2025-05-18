import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../models/director.dart';

class DirectorService {
  final ApiClient _apiClient;
  final String _apiKey = ApiConstants.apiKey;

  DirectorService(this._apiClient);

  Future<Director> getDirectorDetails(int directorId) async {
    try {
      final response = await _apiClient.get(
        '/person/$directorId',
        queryParameters: {
          'api_key': _apiKey,
          'append_to_response': 'movie_credits,tv_credits',
        },
      );
      // The response already includes movie_credits and tv_credits
      return Director.fromJson(response);
    } on DioException catch (e) {
      throw Exception(
          'Failed to fetch director details: [31m${e.message}[0m');
    }
  }

  Future<List<Director>> getMovieDirectors(int movieId) async {
    print('getMovieDirectors called for movie ID: $movieId');
    try {
      print('Fetching directors for movie ID: $movieId');
      // Fetch credits endpoint directly
      final response = await _apiClient.get(
        '/movie/$movieId/credits',
        queryParameters: {
          'api_key': _apiKey,
        },
      );

      if (!response.containsKey('crew')) {
        print('No crew found for movie $movieId');
        print('Full credits: \\$response');
        return [];
      }

      final crew = response['crew'] as List;
      print('Found \\${crew.length} crew members for movie $movieId');
      if (crew.isEmpty) {
        print('Crew list is empty! Full response: \\$response');
      } else {
        print('First 3 crew entries:');
        for (var i = 0; i < crew.length && i < 3; i++) {
          print(crew[i].toString());
        }
      }

      final directors = crew
          .where((member) =>
              (member['job'] ?? '').toString().toLowerCase() == 'director')
          .map((member) => Director(
                id: member['id'],
                name: member['name'] ?? '',
                profilePath: member['profile_path'],
                biography: null,
                birthday: null,
                placeOfBirth: null,
                knownForDepartment: member['department'],
              ))
          .toList();

      print('Found \\${directors.length} directors for movie: $movieId');
      return directors;
    } on DioException catch (e) {
      print('DioException in getMovieDirectors: \\${e.message}');
      print('Error response: \\${e.response?.data}');
      return [];
    } catch (e) {
      print('Unexpected error in getMovieDirectors: \\$e');
      return [];
    }
  }

  Future<List<Director>> getTvShowDirectors(int tvShowId) async {
    print('getTvShowDirectors called for TV show ID: $tvShowId');
    try {
      print('Fetching directors for TV show ID: $tvShowId');
      final response = await _apiClient.get(
        '/tv/$tvShowId',
        queryParameters: {
          'api_key': _apiKey,
          'append_to_response': 'credits',
        },
      );

      if (!response.containsKey('credits') ||
          !response['credits'].containsKey('crew')) {
        print('No credits or crew data found for TV show $tvShowId');
        print('Full response: \\$response');
        return [];
      }

      final crew = response['credits']['crew'] as List;
      print('Found \\${crew.length} crew members for TV show $tvShowId');
      if (crew.isEmpty) {
        print('Crew list is empty! Full response: \\$response');
      } else {
        print('First 3 crew entries:');
        for (var i = 0; i < crew.length && i < 3; i++) {
          print(crew[i].toString());
        }
      }

      final directors = crew
          .where((member) {
            final job = (member['job'] ?? '').toString().toLowerCase();
            final department =
                (member['department'] ?? '').toString().toLowerCase();
            final isDirector = job == 'director' ||
                job == 'series director' ||
                department == 'directing';
            if (isDirector) {
              print('Found director: \\${member['name']} (\\${member['job']})');
            }
            return isDirector;
          })
          .map((member) => Director(
                id: member['id'],
                name: member['name'] ?? '',
                profilePath: member['profile_path'],
                biography: null,
                birthday: null,
                placeOfBirth: null,
                knownForDepartment: member['department'],
              ))
          .toList();

      print('Found \\${directors.length} directors for TV show: $tvShowId');
      return directors;
    } on DioException catch (e) {
      print('DioException in getTvShowDirectors: \\${e.message}');
      print('Error response: \\${e.response?.data}');
      return [];
    } catch (e) {
      print('Unexpected error in getTvShowDirectors: \\$e');
      return [];
    }
  }
}
