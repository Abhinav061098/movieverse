import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mood.dart';

import '../../viewmodels/movie_view_model.dart';
import '../../viewmodels/tv_show_view_model.dart';

class MoodMoviesWidget extends StatelessWidget {
  const MoodMoviesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: Mood.moods.length,
            itemBuilder: (context, index) {
              final mood = Mood.moods[index];
              return _MoodCard(mood: mood);
            },
          ),
        ),
      ],
    );
  }
}

class _MoodCard extends StatelessWidget {
  final Mood mood;

  const _MoodCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMoodContent(context),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: mood.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mood.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mood.icon,
              color: mood.color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              mood.name,
              style: TextStyle(
                color: mood.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodContent(BuildContext context) {
    final movieViewModel = context.read<MovieViewModel>();
    final tvShowViewModel = context.read<TvShowViewModel>();

    // Get all movies from different categories
    final allMovies = {
      ...movieViewModel.popularMovies,
      ...movieViewModel.topRatedMovies,
      ...movieViewModel.upcomingMovies,
    }.toList();

    // Get all TV shows from different categories
    final allTvShows = {
      ...tvShowViewModel.popularTvShows,
      ...tvShowViewModel.topRatedTvShows,
      ...tvShowViewModel.airingTodayShows,
      ...tvShowViewModel.onTheAirShows,
    }.toList();

    // Filter movies and TV shows by mood genres
    final movies = allMovies
        .where((movie) =>
            movie.genreIds.any((id) => mood.movieGenreIds.contains(id)))
        .toList();
    final tvShows = allTvShows
        .where((show) =>
            show.genreIds.any((id) => mood.tvShowGenreIds.contains(id)))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DefaultTabController(
        length: 2,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mood.color.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(mood.icon, color: mood.color, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${mood.name} Content',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: mood.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                mood.description,
                                style: TextStyle(
                                  color: mood.color.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      indicatorColor: mood.color,
                      labelColor: mood.color,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Movies'),
                        Tab(text: 'TV Shows'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildContentGrid(
                      context,
                      movies,
                      true,
                      scrollController,
                    ),
                    _buildContentGrid(
                      context,
                      tvShows,
                      false,
                      scrollController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentGrid(
    BuildContext context,
    List items,
    bool isMovie,
    ScrollController scrollController,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${isMovie ? 'movies' : 'TV shows'} found for this mood',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaCard(
          item: item,
          isMovie: isMovie,
        );
      },
    );
  }
}

class _MediaCard extends StatelessWidget {
  final dynamic item;
  final bool isMovie;

  const _MediaCard({
    required this.item,
    required this.isMovie,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          isMovie ? '/movieDetails' : '/tvShowDetails',
          arguments: item.id,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.fullPosterPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
