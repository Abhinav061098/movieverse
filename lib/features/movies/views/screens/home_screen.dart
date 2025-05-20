import 'package:flutter/material.dart';
import 'package:movieverse/features/movies/views/widgets/directors_widget.dart';
import 'package:movieverse/features/movies/views/widgets/trending_widget.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/movie_view_model.dart';
import '../../viewmodels/tv_show_view_model.dart';
import '../widgets/media_section_list.dart';
import '../widgets/movie_of_the_day_card.dart';
import '../widgets/genre_chips.dart';
import '../screens/movie_details_screen.dart';
import '../screens/tv_show_details_screen.dart';
import '../widgets/trailer_carousel.dart';
import '../screens/favorites_screen.dart';
import '../screens/watchlist_screen.dart';
import '../../../../core/auth/screens/profile_screen.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/mood_movies_widget.dart';
import '../widgets/popular_people_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        if (movieViewModel.state == MovieListState.error ||
            tvShowViewModel.state == TvShowListState.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Movie Error: \n${movieViewModel.error}\n\nTV Show Error: \n${tvShowViewModel.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                tooltip: 'Profile',
              ),
            ],
          ),
          body: _buildCurrentTab(movieViewModel, tvShowViewModel),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.movie_outlined),
                  activeIcon: Icon(Icons.movie),
                  label: 'Movies'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.tv_outlined),
                  activeIcon: Icon(Icons.tv),
                  label: 'TV Shows'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Favorites'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_outlined),
                  activeIcon: Icon(Icons.list),
                  label: 'Watchlists'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab(
      MovieViewModel movieViewModel, TvShowViewModel tvShowViewModel) {
    switch (_currentIndex) {
      case 0:
        return _buildMoviesTab(movieViewModel);
      case 1:
        return _buildTvShowsTab(tvShowViewModel);
      case 2:
        return const FavoritesScreen();
      case 3:
        return const WatchlistScreen();
      default:
        return _buildMoviesTab(movieViewModel);
    }
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
            // Movie of the Day
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
              )
            else
              const ShimmerMovieOfTheDay(),
            const SizedBox(height: 16),
            const TrendingWidget(mediaType: 'movie'),
            const SizedBox(height: 24),

            // Genres
            if (movieViewModel.genres.isNotEmpty)
              GenreChips(
                genres: movieViewModel.genres,
                selectedGenreId: movieViewModel.selectedGenreId,
                onGenreSelected: movieViewModel.setSelectedGenre,
              )
            else
              const ShimmerSectionTitle(),

            const SizedBox(height: 16),

            // Popular Movies
            if (movieViewModel.popularMovies.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // Top Rated Movies
            if (movieViewModel.topRatedMovies.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // Upcoming Movies
            if (movieViewModel.upcomingMovies.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // Trailers
            if (movieViewModel.trailers.isNotEmpty)
              TrailerCarousel(trailers: movieViewModel.trailers)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) =>
                          const ShimmerTrailerCard(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Directors
            if (movieViewModel.popularDirectors.isNotEmpty)
              DirectorsWidget(
                directors: movieViewModel.popularDirectors,
                title: 'Directors',
                isLoading: movieViewModel.state == MovieListState.loading &&
                    movieViewModel.popularDirectors.isEmpty,
                onSeeAllPressed: () {
                  movieViewModel.loadMoreDirectors();
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const ShimmerDirectorCard(),
                    ),
                  ),
                ],
              ),
            const PopularPeopleWidget(),
            const SizedBox(height: 16),
            const MoodMoviesWidget(),

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
            const TrendingWidget(mediaType: 'tv'),
            const SizedBox(height: 16),
            // Genres
            if (tvShowViewModel.genres.isNotEmpty)
              GenreChips(
                genres: tvShowViewModel.genres,
                selectedGenreId: tvShowViewModel.selectedGenreId,
                onGenreSelected: tvShowViewModel.setSelectedGenre,
              )
            else
              const ShimmerSectionTitle(),

            const SizedBox(height: 16),

            // Popular TV Shows
            if (tvShowViewModel.popularTvShows.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // Top Rated TV Shows
            if (tvShowViewModel.topRatedTvShows.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // Airing Today
            if (tvShowViewModel.airingTodayShows.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            // On The Air
            if (tvShowViewModel.onTheAirShows.isNotEmpty)
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
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 286,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) => const ShimmerMovieCard(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Directors
            if (tvShowViewModel.popularDirectors.isNotEmpty)
              DirectorsWidget(
                directors: tvShowViewModel.popularDirectors,
                title: 'Directors',
                onSeeAllPressed: () {
                  tvShowViewModel.loadMoreDirectors();
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerSectionTitle(),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const ShimmerDirectorCard(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 38),
          ],
        ),
      ),
    );
  }
}
