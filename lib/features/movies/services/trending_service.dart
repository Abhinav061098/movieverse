import '../../../core/api/api_client.dart';

class TrendingService {
  final ApiClient _apiClient;
  TrendingService(this._apiClient);

  Future<List<dynamic>> getTrending(
      {String mediaType = 'all', String timeWindow = 'day'}) async {
    final response = await _apiClient.get(
      '/trending/$mediaType/$timeWindow',
    );
    return response['results'] as List<dynamic>;
  }
}
