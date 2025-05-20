import '../../../core/api/api_client.dart';

class PersonService {
  final ApiClient _apiClient;
  PersonService(this._apiClient);

  Future<List<dynamic>> getPopularPeople({int page = 1}) async {
    final response = await _apiClient.get(
      '/person/popular',
      queryParameters: {'page': page},
    );
    return response['results'] as List<dynamic>;
  }
}
