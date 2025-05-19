import '../../../core/api/api_client.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _apiClient;

  ReviewService(this._apiClient);

  Future<List<Review>> getMovieReviews(int movieId, {int page = 1}) async {
    final response = await _apiClient.get(
      '/movie/$movieId/reviews',
      queryParameters: {'page': page},
    );

    final results = response['results'] as List;
    return results.map((review) => Review.fromJson(review)).toList();
  }

  Future<List<Review>> getTvShowReviews(int tvId, {int page = 1}) async {
    final response = await _apiClient.get(
      '/tv/$tvId/reviews',
      queryParameters: {'page': page},
    );

    final results = response['results'] as List;
    return results.map((review) => Review.fromJson(review)).toList();
  }
}
