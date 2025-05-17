import 'package:flutter/material.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_service.dart';
import '../../services/watchlist_service.dart';

class EngagementInsights extends StatelessWidget {
  const EngagementInsights({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your MovieVerse Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<dynamic>>(
            stream: Future.wait([
              context.read<FavoritesService>().favoritesStream.first,
              Future.value(context.read<WatchlistService>().watchlists),
            ]).asStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final favorites = snapshot.data![0] as List;
              final watchlists = snapshot.data![1] as List;

              final moviesCount = favorites
                  .where((item) => item.item.mediaType == 'movie')
                  .length;
              final tvShowsCount =
                  favorites.where((item) => item.item.mediaType == 'tv').length;

              // Log engagement stats view
              context
                  .read<FirebaseService>()
                  .logEvent('view_engagement_stats', {
                'favorite_movies': moviesCount,
                'favorite_tv_shows': tvShowsCount,
                'watchlists': watchlists.length,
                'timestamp': DateTime.now().toIso8601String(),
              });

              return Column(
                children: [
                  _buildStatRow(
                    context,
                    'Favorite Movies',
                    moviesCount.toString(),
                    Icons.movie_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Favorite TV Shows',
                    tvShowsCount.toString(),
                    Icons.tv_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Watchlists Created',
                    watchlists.length.toString(),
                    Icons.list_alt_outlined,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
