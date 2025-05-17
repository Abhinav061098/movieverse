import 'dart:math';

import '../models/media_item.dart';
import '../services/movie_service.dart';
import '../services/tv_service.dart';
import 'favorites_service.dart';
import 'watchlist_service.dart';

class RecommendationService {
  final MovieService movieService;
  final TvService tvService;
  final FavoritesService favoritesService;
  final WatchlistService watchlistService;

  RecommendationService({
    required this.movieService,
    required this.tvService,
    required this.favoritesService,
    required this.watchlistService,
  });

  List<int> _getExcludedIds(String mediaType) {
    final favoriteIds = favoritesService.currentFavorites
        .where((item) => item.mediaType == mediaType)
        .map((item) => item.id)
        .toSet();
    final watchlistIds = watchlistService.watchlists
        .expand((w) => w.items.values)
        .where((item) => item.item.mediaType == mediaType)
        .map((item) => item.item.id)
        .toSet();
    return {...favoriteIds, ...watchlistIds}.toList();
  }

  Future<List<MediaItem>> getMovieRecommendationsByGenres(
      List<int> preferredGenres,
      {int limit = 10}) async {
    final excludedIds = _getExcludedIds('movie');
    final recommendations = <MediaItem>[];
    final genresToUse = preferredGenres.take(5).toList();
    final random = Random();

    for (final genreId in genresToUse) {
      final movies = await movieService.getPopularMoviesByGenres([genreId]);
      final filtered =
          movies.where((movie) => !excludedIds.contains(movie.id)).toList();
      if (filtered.isNotEmpty) {
        final movie = filtered[random.nextInt(filtered.length)];
        final json = movie.toJson();
        json['media_type'] = 'movie';
        // Avoid duplicates
        if (!recommendations.any((m) => m.id == movie.id)) {
          recommendations.add(MediaItem(json));
        }
      }
      if (recommendations.length >= limit) break;
    }
    // If not enough, fill with more randoms from all genres
    if (recommendations.length < limit) {
      final allMovies =
          await movieService.getPopularMoviesByGenres(genresToUse);
      final filtered = allMovies
          .where((movie) =>
              !excludedIds.contains(movie.id) &&
              !recommendations.any((m) => m.id == movie.id))
          .toList();
      filtered.shuffle(random);
      for (final movie in filtered) {
        final json = movie.toJson();
        json['media_type'] = 'movie';
        recommendations.add(MediaItem(json));
        if (recommendations.length >= limit) break;
      }
    }
    return recommendations.take(limit).toList();
  }

  Future<List<MediaItem>> getTvShowRecommendationsByGenres(
      List<int> preferredGenres,
      {int limit = 10}) async {
    final excludedIds = _getExcludedIds('tv');
    final recommendations = <MediaItem>[];
    // Try popular first
    final popular = await tvService.getPopularTvShowsByGenres(preferredGenres);
    for (final show in popular) {
      final json = show.toJson();
      json['media_type'] = 'tv'; // Ensure media_type is present
      if (!excludedIds.contains(show.id)) {
        recommendations.add(MediaItem(json));
        if (recommendations.length >= limit) break;
      }
    }
    // Fallback to top-rated if not enough
    if (recommendations.length < limit) {
      final topRated =
          await tvService.getTopRatedTvShowsByGenres(preferredGenres);
      for (final show in topRated) {
        final json = show.toJson();
        json['media_type'] = 'tv'; // Ensure media_type is present
        if (!excludedIds.contains(show.id) &&
            !recommendations.any((m) => m.id == show.id)) {
          recommendations.add(MediaItem(json));
          if (recommendations.length >= limit) break;
        }
      }
    }
    return recommendations.take(limit).toList();
  }
}
