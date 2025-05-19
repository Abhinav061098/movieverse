import 'package:movieverse/core/api/api_client.dart';
import '../models/cast.dart';

class CastService {
  final ApiClient apiClient;
  CastService(this.apiClient);

  Future<Cast> fetchCastDetails(int castId) async {
    final response = await apiClient.get(
      '/person/$castId',
      queryParameters: {
        'append_to_response': 'movie_credits,tv_credits,external_ids',
      },
    );
    return Cast.fromJson(response);
  }
}
