import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/movie_view_model.dart';
import '../../viewmodels/tv_show_view_model.dart';
import '../widgets/media_section_list.dart';
import '../widgets/movie_of_the_day_card.dart';
import '../widgets/genre_chips.dart';
import '../screens/movie_details_screen.dart';
import '../screens/tv_show_details_screen.dart';
import '../widgets/trailer_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<MovieViewModel>().loadInitialData();
      context.read<TvShowViewModel>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MovieViewModel, TvShowViewModel>(
      builder: (context, movieViewModel, tvShowViewModel, child) {
        if (movieViewModel.state == MovieListState.loading ||
            tvShowViewModel.state == TvShowListState.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (movieViewModel.state == MovieListState.error ||
            tvShowViewModel.state == TvShowListState.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(movieViewModel.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      movieViewModel.loadInitialData();
                      tvShowViewModel.loadInitialData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('MovieVerse'),
          ),
          body: _currentIndex == 0
              ? _buildMoviesTab(movieViewModel)
              : _buildTvShowsTab(tvShowViewModel),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Movies'),
              BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'TV Shows'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoviesTab(MovieViewModel movieViewModel) {
    return RefreshIndicator(
      onRefresh: () {
        return movieViewModel.refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (movieViewModel.movieOfTheDay != null)
              MovieOfTheDayCard(
                movie: movieViewModel.movieOfTheDay!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(
                        movieId: movieViewModel.movieOfTheDay!.id,
                      ),
                    ),
                  );
                },
              ),
            GenreChips(
              genres: movieViewModel.genres,
              selectedGenreId: movieViewModel.selectedGenreId,
              onGenreSelected: movieViewModel.setSelectedGenre,
            ),
            const SizedBox(height: 16),
            MediaSectionList(
              title: 'Popular Movies',
              mediaList: movieViewModel.filteredPopularMovies,
              isLoadingMore: movieViewModel.isLoadingMorePopularMovies,
              onLoadMore: movieViewModel.loadMorePopularMovies,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movieId: media.id),
                  ),
                );
              },
            ),
            MediaSectionList(
              title: 'Top Rated Movies',
              mediaList: movieViewModel.filteredTopRatedMovies,
              isLoadingMore: movieViewModel.isLoadingMoreTopRatedMovies,
              onLoadMore: movieViewModel.loadMoreTopRatedMovies,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movieId: media.id),
                  ),
                );
              },
            ),
            MediaSectionList(
              title: 'Upcoming Movies',
              mediaList: movieViewModel.filteredUpcomingMovies,
              isLoadingMore: movieViewModel.isLoadingMoreUpcomingMovies,
              onLoadMore: movieViewModel.loadMoreUpcomingMovies,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movieId: media.id),
                  ),
                );
              },
            ),
            if (movieViewModel.trailers.isNotEmpty)
              TrailerCarousel(trailers: movieViewModel.trailers),
            const SizedBox(height: 38),
          ],
        ),
      ),
    );
  }

  Widget _buildTvShowsTab(TvShowViewModel tvShowViewModel) {
    return RefreshIndicator(
      onRefresh: () {
        return tvShowViewModel.refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            GenreChips(
              genres: tvShowViewModel.genres,
              selectedGenreId: tvShowViewModel.selectedGenreId,
              onGenreSelected: tvShowViewModel.setSelectedGenre,
            ),
            const SizedBox(height: 16),
            MediaSectionList(
              title: 'Popular TV Shows',
              mediaList: tvShowViewModel.filteredPopularTvShows,
              isLoadingMore: tvShowViewModel.isLoadingMorePopularTvShows,
              onLoadMore: tvShowViewModel.loadMorePopularTvShows,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TvShowDetailsScreen(tvShowId: media.id),
                  ),
                );
              },
            ),
            MediaSectionList(
              title: 'Top Rated TV Shows',
              mediaList: tvShowViewModel.filteredTopRatedTvShows,
              isLoadingMore: tvShowViewModel.isLoadingMoreTopRatedTvShows,
              onLoadMore: tvShowViewModel.loadMoreTopRatedTvShows,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TvShowDetailsScreen(tvShowId: media.id),
                  ),
                );
              },
            ),
            MediaSectionList(
              title: 'Airing Today',
              mediaList: tvShowViewModel.filteredAiringTodayShows,
              isLoadingMore: tvShowViewModel.isLoadingMoreAiringTodayShows,
              onLoadMore: tvShowViewModel.loadMoreAiringTodayShows,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TvShowDetailsScreen(tvShowId: media.id),
                  ),
                );
              },
            ),
            MediaSectionList(
              title: 'On The Air',
              mediaList: tvShowViewModel.filteredOnTheAirShows,
              isLoadingMore: tvShowViewModel.isLoadingMoreOnTheAirShows,
              onLoadMore: tvShowViewModel.loadMoreOnTheAirShows,
              onMediaTap: (media) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TvShowDetailsScreen(tvShowId: media.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
