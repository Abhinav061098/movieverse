import 'package:flutter/material.dart';
import 'package:movieverse/core/mixins/analytics_mixin.dart';
import 'package:movieverse/features/movies/models/media_item.dart';
import 'package:movieverse/features/movies/services/favorites_service.dart';
import 'package:movieverse/features/movies/views/widgets/trending_content.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../viewmodels/media_list_viewmodel.dart';
import '../widgets/trailer_carousel.dart';
import '../widgets/media_section_list.dart';
import '../widgets/movie_of_the_day_card.dart';
import './favorites_screen.dart';
import '../../../../features/auth/screens/profile_screen.dart';
import './watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AnalyticsMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<MediaListViewModel>().loadInitialData();
    });
  }

  void _handleSignOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaListViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.state == MediaListState.loading &&
            _currentIndex != 2 &&
            _currentIndex != 3) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('MovieVerse'),
            actions: [
              if (_currentIndex != 2 && _currentIndex != 3)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: viewModel.startSearch,
                ),
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
                tooltip: 'Profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleSignOut,
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildMoviesTab(viewModel),
              _buildTvShowsTab(viewModel),
              const FavoritesScreen(),
              const WatchlistScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            onTap: (index) async {
              // Set state immediately for better UX
              setState(() {
                _currentIndex = index;
              });

              // Only update media type if switching between movies and TV shows
              if (index <= 1) {
                final newType = index == 0 ? MediaType.movie : MediaType.tvShow;
                if (viewModel.selectedMediaType != newType) {
                  // Reset genre filter and sync genre view model with media type
                  await viewModel.setMediaType(newType);
                }
              }

              logEvent('tab_changed', {
                'from': _getTabName(_currentIndex),
                'to': _getTabName(index),
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_outlined),
                activeIcon: Icon(Icons.movie),
                label: 'Movies',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tv_outlined),
                activeIcon: Icon(Icons.tv),
                label: 'TV Shows',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_outlined),
                activeIcon: Icon(Icons.list),
                label: 'Watchlists',
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Movies';
      case 1:
        return 'TV Shows';
      case 2:
        return 'Favorites';
      case 3:
        return 'Watchlists';
      default:
        return '';
    }
  }

  Widget _buildMoviesTab(MediaListViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () {
        logEvent('refresh_movies_tab', {});
        return viewModel.refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (viewModel.movieOfTheDay != null)
              MovieOfTheDayCard(
                movie: viewModel.movieOfTheDay!,
                onTap: () => viewModel.navigateToDetails(
                  context,
                  viewModel.movieOfTheDay,
                ),
              ),
            TrendingContent(mediaType: MediaType.movie),
            const SizedBox(height: 16),
            MediaSectionList(
              title: 'Popular Movies',
              mediaList: viewModel.popularMovies,
              isLoadingMore: viewModel.isLoadingMorePopularMovies,
              onLoadMore: viewModel.loadMorePopularMovies,
            ),
            MediaSectionList(
              title: 'Top Rated Movies',
              mediaList: viewModel.topRatedMovies,
              isLoadingMore: viewModel.isLoadingMoreTopRatedMovies,
              onLoadMore: viewModel.loadMoreTopRatedMovies,
            ),
            MediaSectionList(
              title: 'Upcoming Movies',
              mediaList: viewModel.upcomingMovies,
              isLoadingMore: viewModel.isLoadingMoreUpcomingMovies,
              onLoadMore: viewModel.loadMoreUpcomingMovies,
            ),
            if (viewModel.latestTrailers.isNotEmpty)
              TrailerCarousel(trailers: viewModel.latestTrailers),
            const SizedBox(height: 16),
            Consumer<FavoritesService>(
              builder: (context, favoritesService, child) {
                return StreamBuilder<List<MediaItem>>(
                  stream: favoritesService.favoritesStream,
                  initialData: favoritesService.currentFavorites,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final favorites = snapshot.data!
                        .where((item) => item.item.mediaType == 'movie')
                        .toList();

                    if (favorites.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return MediaSectionList(
                      title: 'Favorites',
                      mediaList: favorites.map((f) => f.item).toList(),
                      isLoadingMore: false,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 38),
          ],
        ),
      ),
    );
  }

  Widget _buildTvShowsTab(MediaListViewModel viewModel) {
    if (viewModel.popularTvShows.isEmpty &&
        viewModel.state != MediaListState.loading) {
      Future.microtask(() => viewModel.setMediaType(MediaType.tvShow));
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () {
        logEvent('refresh_tv_shows_tab', {});
        return viewModel.refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            MediaSectionList(
              title: 'Popular TV Shows',
              mediaList: viewModel.popularTvShows,
              isLoadingMore: viewModel.isLoadingMorePopularTvShows,
              onLoadMore: viewModel.loadMorePopularTvShows,
            ),
            MediaSectionList(
              title: 'Top Rated Shows',
              mediaList: viewModel.topRatedTvShows,
              isLoadingMore: viewModel.isLoadingMoreTopRatedTvShows,
              onLoadMore: viewModel.loadMoreTopRatedTvShows,
            ),
            MediaSectionList(
              title: 'Airing Today',
              mediaList: viewModel.airingTodayShows,
              isLoadingMore: viewModel.isLoadingMoreAiringTodayShows,
              onLoadMore: viewModel.loadMoreAiringTodayShows,
            ),
            MediaSectionList(
              title: 'On The Air',
              mediaList: viewModel.onTheAirShows,
              isLoadingMore: viewModel.isLoadingMoreOnTheAirShows,
              onLoadMore: viewModel.loadMoreOnTheAirShows,
            ),
            TrendingContent(mediaType: MediaType.tvShow),
            const SizedBox(height: 16),

            // Add Favorites section
            Consumer<FavoritesService>(
              builder: (context, favoritesService, child) {
                return StreamBuilder<List<MediaItem>>(
                  stream: favoritesService.favoritesStream,
                  initialData: favoritesService.currentFavorites,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final favorites = snapshot.data!
                        .where((item) => item.item.mediaType == 'tv')
                        .toList();

                    if (favorites.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return MediaSectionList(
                      title: 'Favorites',
                      mediaList: favorites.map((f) => f.item).toList(),
                      isLoadingMore: false,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 38),
          ],
        ),
      ),
    );
  }
}
