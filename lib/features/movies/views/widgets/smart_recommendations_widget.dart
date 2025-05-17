import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/media_card.dart';
import '../../models/media_item.dart';
import '../../services/recommendation_service.dart';
import '../../services/movie_service.dart';
import '../../services/tv_service.dart';
import '../../services/favorites_service.dart';
import '../../services/watchlist_service.dart';

class SmartRecommendationsWidget extends StatelessWidget {
  final List<int> preferredGenres;
  final bool isMovie;

  const SmartRecommendationsWidget({
    super.key,
    this.preferredGenres = const [28, 12, 16], // Example genre IDs
    this.isMovie = true,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final movieService = context.read<MovieService>();
      final tvService = context.read<TvService>();
      final favoritesService = context.read<FavoritesService>();
      final watchlistService = context.read<WatchlistService>();

      final recommendationService = RecommendationService(
        movieService: movieService,
        tvService: tvService,
        favoritesService: favoritesService,
        watchlistService: watchlistService,
      );

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.movie_filter,
                          size: 16,
                          color: Colors.blue[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<MediaItem>>(
              future: isMovie
                  ? recommendationService.getMovieRecommendationsByGenres(
                      preferredGenres,
                      limit: 5)
                  : recommendationService.getTvShowRecommendationsByGenres(
                      preferredGenres,
                      limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint(
                      'SmartRecommendationsWidget error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Error loading recommendations',
                              style: TextStyle(color: Colors.grey[400]),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}', // Show the error message
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 12),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                final recommendations = snapshot.data ?? [];
                if (recommendations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.movie_filter,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                            'No recommendations available yet.\nKeep watching movies to get personalized suggestions!',
                            style: TextStyle(color: Colors.grey[400]),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final media = recommendations[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: MediaCard(
                              media: media,
                              onTap: () {
                                // TODO: Navigate to the correct details screen based on media type
                                // Example:
                                if (media.mediaType == 'movie') {
                                  Navigator.pushNamed(context, '/movieDetails',
                                      arguments: media.id);
                                } else if (media.mediaType == 'tv') {
                                  Navigator.pushNamed(context, '/tvShowDetails',
                                      arguments: media.id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              Text('Suggestions based on your favorite genres',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogTheme: DialogThemeData(
                                        backgroundColor: Colors.grey[900]),
                                  ),
                                  child: AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.movie_filter),
                                        SizedBox(width: 8),
                                        Text('Recommendations'),
                                      ],
                                    ),
                                    content: const Text(
                                        'These recommendations are based on popular movies and shows that match your favorite genres. We analyze your viewing history to understand which genres you enjoy most.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Got it'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Learn More',
                                style: TextStyle(
                                    color: Colors.blue[300], fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'A required Provider is missing above SmartRecommendationsWidget.\n\nError: \n$e\n\nMake sure MovieService, TvService, FavoritesService, and WatchlistService are provided higher in the widget tree.',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}
