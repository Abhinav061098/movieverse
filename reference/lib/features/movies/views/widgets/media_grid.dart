import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/media_card.dart';
import '../../models/media_item.dart';
import '../../viewmodels/media_list_viewmodel.dart';
import '../../services/favorites_service.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../models/movie_details.dart';
import '../../models/tv_show_details.dart';
import '../../models/credits.dart';
import '../../models/video_response.dart';
import '../../models/genre.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final Function(MediaItem)? onRemove;

  const MediaGrid({
    super.key,
    required this.items,
    this.onRemove,
  });

  MovieDetails _convertToMovieDetails(Movie movie) {
    return MovieDetails(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      releaseDate: movie.releaseDate,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      voteAverage: movie.voteAverage,
      runtime: 0, // Default value since not available in Movie model
      genres: movie.genreIds.map((id) => Genre(id: id, name: '')).toList(),
      credits: Credits.empty(),
      videos: VideoResponse.empty(),
    );
  }

  TvShowDetails _convertToTvShowDetails(TvShow show) {
    return TvShowDetails(
      id: show.id,
      title: show.title,
      overview: show.overview,
      firstAirDate: show.firstAirDate,
      posterPath: show.posterPath,
      backdropPath: show.backdropPath,
      voteAverage: show.voteAverage,
      numberOfSeasons: 0, // Default value since not available in TvShow model
      genres: show.genreIds.map((id) => Genre(id: id, name: '')).toList(),
      credits: Credits.empty(),
      videos: VideoResponse.empty(),
      seasons: const [], // Empty list since not available in TvShow model
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final mediaItem = items[index];
        final media = mediaItem.item;

        return Dismissible(
          key: Key('media_${mediaItem.id}'),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) async {
            try {
              final favoritesService = context.read<FavoritesService>();
              if (mediaItem.item.mediaType == 'movie') {
                await favoritesService.toggleMovieFavorite(
                  mediaItem.item.id,
                  details: _convertToMovieDetails(mediaItem.item as Movie),
                );
              } else {
                await favoritesService.toggleTvShowFavorite(
                  mediaItem.item.id,
                  details: _convertToTvShowDetails(mediaItem.item as TvShow),
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed from favorites'),
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error removing from favorites: $e'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: MediaCard(
            media: media,
            onTap: () {
              context.read<MediaListViewModel>().navigateToDetails(
                    context,
                    media,
                  );
            },
          ),
        );
      },
    );
  }
}
