import 'package:flutter/material.dart';
import 'package:movieverse/core/mixins/analytics_mixin.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../services/favorites_service.dart';
import '../widgets/media_grid.dart';
import '../widgets/favorite_genre_filter.dart';
import '../../models/genre.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with AnalyticsMixin {
  bool _showMovies = true;
  int? _selectedGenreId;

  void _handleGenreSelected(int? genreId) {
    setState(() {
      _selectedGenreId = genreId;
    });

    logFeatureUsage(
      featureName: 'favorites_filter',
      action: 'apply_genre_filter',
      parameters: {
        'genre_id': genreId?.toString() ?? 'all',
        'content_type': _showMovies ? 'movie' : 'tv_show',
      },
    );
  }

  void _toggleMediaType() {
    setState(() {
      _showMovies = !_showMovies;
      _selectedGenreId = null; // Reset genre filter when switching media type
    });

    logFeatureUsage(
      featureName: 'favorites_filter',
      action: 'switch_media_type',
      parameters: {
        'new_type': _showMovies ? 'movie' : 'tv_show',
      },
    );
  }

  // Calculate genre counts from favorites
  Map<int, int> _calculateGenreCounts(List<MediaItem> favorites) {
    final Map<int, int> counts = {};
    for (final item in favorites) {
      if ((_showMovies && item.mediaType == 'movie') ||
          (!_showMovies && item.mediaType == 'tv')) {
        final genreIds = item.item.genreIds as List<dynamic>;
        for (final genreId in genreIds) {
          counts[genreId] = (counts[genreId] ?? 0) + 1;
        }
      }
    }

    logContentImpression(
      contentType: 'favorites_summary',
      contentId: 'genre_distribution',
      section: 'favorites_screen',
      source: _showMovies ? 'movies' : 'tv_shows',
    );

    return counts;
  }

  // Get list of genres from favorites
  List<Genre> _getGenresFromFavorites(List<MediaItem> favorites) {
    final Set<int> uniqueGenreIds = {};
    for (final item in favorites) {
      if ((_showMovies && item.mediaType == 'movie') ||
          (!_showMovies && item.mediaType == 'tv')) {
        final genreIds = item.item.genreIds as List<dynamic>;
        uniqueGenreIds.addAll(genreIds.cast<int>());
      }
    }

    return uniqueGenreIds
        .map((id) => Genre(id: id, name: _getGenreName(id)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get genre name from ID
  String _getGenreName(int id) {
    // Common movie and TV show genres
    switch (id) {
      case 28:
        return 'Action';
      case 12:
        return 'Adventure';
      case 16:
        return 'Animation';
      case 35:
        return 'Comedy';
      case 80:
        return 'Crime';
      case 99:
        return 'Documentary';
      case 18:
        return 'Drama';
      case 10751:
        return 'Family';
      case 14:
        return 'Fantasy';
      case 36:
        return 'History';
      case 27:
        return 'Horror';
      case 10402:
        return 'Music';
      case 9648:
        return 'Mystery';
      case 10749:
        return 'Romance';
      case 878:
        return 'Science Fiction';
      case 10770:
        return 'TV Movie';
      case 53:
        return 'Thriller';
      case 10752:
        return 'War';
      case 37:
        return 'Western';
      default:
        return 'Genre $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Consumer<FavoritesService>(
            builder: (context, favoritesService, child) {
              return StreamBuilder<List<MediaItem>>(
                stream: favoritesService.favoritesStream,
                initialData: favoritesService.currentFavorites,
                builder: (context, snapshot) {
                  final favorites = snapshot.data ?? [];
                  final genreCounts = _calculateGenreCounts(favorites);
                  final genres = _getGenresFromFavorites(favorites);

                  return FavoriteGenreFilter(
                    genres: genres,
                    selectedGenreId: _selectedGenreId,
                    onGenreSelected: _handleGenreSelected,
                    genreCounts: genreCounts,
                  );
                },
              );
            },
          ),
          Expanded(
            child: Consumer<FavoritesService>(
              builder: (context, favoritesService, child) {
                return StreamBuilder<List<MediaItem>>(
                  stream: favoritesService.favoritesStream,
                  initialData: favoritesService.currentFavorites,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No favorites yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final favorites = snapshot.data!;
                    final filteredFavorites = favorites.where((item) {
                      final isCorrectType = _showMovies
                          ? item.mediaType == 'movie'
                          : item.mediaType == 'tv';

                      final hasSelectedGenre = _selectedGenreId == null ||
                          (item.item.genreIds as List<dynamic>)
                              .contains(_selectedGenreId);

                      return isCorrectType && hasSelectedGenre;
                    }).toList();

                    if (filteredFavorites.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedGenreId != null
                              ? 'No favorites in this genre'
                              : _showMovies
                                  ? 'No favorite movies yet'
                                  : 'No favorite TV shows yet',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return MediaGrid(
                      items: filteredFavorites,
                      onTap: (mediaItem) {
                        if (mediaItem.mediaType == 'movie') {
                          Navigator.pushNamed(
                            context,
                            '/movieDetails',
                            arguments: mediaItem.item.id,
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/tvShowDetails',
                            arguments: mediaItem.item.id,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'toggle_media_type_fab',
        onPressed: _toggleMediaType,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(_showMovies ? Icons.tv : Icons.movie),
      ),
    );
  }
}
