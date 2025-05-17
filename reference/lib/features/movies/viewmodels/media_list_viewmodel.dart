import 'package:flutter/material.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:movieverse/features/movies/models/media_item.dart';
import 'package:movieverse/features/movies/models/movie_details.dart';
import '../models/movie.dart';
import '../models/tv_show.dart';
import '../models/movie_trailer.dart';
import '../services/movie_service.dart';
import '../services/tv_service.dart';
import '../views/screens/movie_details_screen.dart';
import '../views/screens/tv_show_details_screen.dart';

enum MediaListState { initial, loading, loaded, error }

enum MediaType { movie, tvShow }

class MediaListViewModel with ChangeNotifier {
  final MovieService _movieService;
  final TvService _tvService;
  final FirebaseService _firebaseService = FirebaseService();
  MediaListState _state = MediaListState.initial;
  String _error = '';
  MediaType _selectedMediaType = MediaType.movie;

  // Lists
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];

  // TV Shows
  List<TvShow> _popularTvShows = [];
  List<TvShow> _topRatedTvShows = [];
  List<TvShow> _airingTodayShows = [];
  List<TvShow> _onTheAirShows = [];

  // Search
  bool _isSearching = false;
  List<MediaItem> _searchResults = [];
  List<String> _searchHistory = [];
  String _currentSearchQuery = '';
  int _searchPage = 1;
  bool _isLoadingMoreSearch = false;
  bool _hasMoreSearchResults = true;

  // Pages
  int _popularMoviesPage = 1;
  int _topRatedMoviesPage = 1;
  int _upcomingMoviesPage = 1;
  int _popularTvShowsPage = 1;
  int _topRatedTvShowsPage = 1;
  int _airingTodayShowsPage = 1;
  int _onTheAirShowsPage = 1;

  // Flags for pagination
  bool _hasMorePopularMovies = true;
  bool _hasMoreTopRatedMovies = true;
  bool _hasMoreUpcomingMovies = true;
  bool _hasMorePopularTvShows = true;
  bool _hasMoreTopRatedTvShows = true;
  bool _hasMoreAiringTodayShows = true;
  bool _hasMoreOnTheAirShows = true;

  // Loading states
  bool _isLoadingMorePopularMovies = false;
  bool _isLoadingMoreTopRatedMovies = false;
  bool _isLoadingMoreUpcomingMovies = false;
  bool _isLoadingMorePopularTvShows = false;
  bool _isLoadingMoreTopRatedTvShows = false;
  bool _isLoadingMoreAiringTodayTvShows = false;
  bool _isLoadingMoreOnTheAirTvShows = false;

  MovieDetails? _movieOfTheDay;
  List<MovieTrailer> _latestTrailers = [];

  MediaListViewModel(this._movieService, this._tvService);

  // Getters
  MediaListState get state => _state;
  String get error => _error;
  MediaType get selectedMediaType => _selectedMediaType;

  bool get isSearching => _isSearching;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  List<MediaItem> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  MovieService get movieService => _movieService;
  TvService get tvService => _tvService;

  // Movie getters
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  MovieDetails? get movieOfTheDay => _movieOfTheDay;
  List<MovieTrailer> get latestTrailers => _latestTrailers;

  // TV Show getters
  List<TvShow> get popularTvShows => _popularTvShows;
  List<TvShow> get topRatedTvShows => _topRatedTvShows;
  List<TvShow> get airingTodayShows => _airingTodayShows;
  List<TvShow> get onTheAirShows => _onTheAirShows;

  // "Load more" state getters
  bool get isLoadingMorePopularMovies => _isLoadingMorePopularMovies;
  bool get isLoadingMoreTopRatedMovies => _isLoadingMoreTopRatedMovies;
  bool get isLoadingMoreUpcomingMovies => _isLoadingMoreUpcomingMovies;
  bool get isLoadingMorePopularTvShows => _isLoadingMorePopularTvShows;
  bool get isLoadingMoreTopRatedTvShows => _isLoadingMoreTopRatedTvShows;
  bool get isLoadingMoreAiringTodayShows => _isLoadingMoreAiringTodayTvShows;
  bool get isLoadingMoreOnTheAirShows => _isLoadingMoreOnTheAirTvShows;

  // Methods
  Future<void> setMediaType(MediaType type) async {
    if (_selectedMediaType == type) return;

    _selectedMediaType = type;

    try {
      if (type == MediaType.movie) {
        if (_popularMovies.isEmpty) {
          _state = MediaListState.loading;
          notifyListeners();
          await _loadMoviesData();
        }
      } else {
        if (_popularTvShows.isEmpty) {
          _state = MediaListState.loading;
          notifyListeners();
          await _loadTvShowsData();
        }
      }

      _state = MediaListState.loaded;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = MediaListState.error;
      notifyListeners();
    }
  }

  // Loading initial data
  Future<void> loadInitialData() async {
    if (_state == MediaListState.loading) return;

    _state = MediaListState.loading;
    notifyListeners();

    try {
      await _loadMoviesData();

      _state = MediaListState.loaded;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = MediaListState.error;
      notifyListeners();
    }
  }

  Future<void> _loadMoviesData() async {
    try {
      final results = await Future.wait([
        _movieService.getPopularMovies(page: _popularMoviesPage),
        _movieService.getTopRatedMovies(page: _topRatedMoviesPage),
        _movieService.getUpcomingMovies(page: _upcomingMoviesPage),
      ]);

      _popularMovies = results[0];
      _topRatedMovies = results[1];
      _upcomingMovies = results[2];

      // Load movie of the day if not already loaded
      if (_movieOfTheDay == null) {
        try {
          _movieOfTheDay = await _movieService.getMovieOfTheDay();
        } catch (e) {
          debugPrint('Failed to load Movie of the Day: $e');
          // Fallback to the first popular movie if available
          if (_popularMovies.isNotEmpty) {
            _movieOfTheDay = await _movieService.getMovieDetails(
              _popularMovies.first.id,
            ) as MovieDetails?;
          }
        }
      }

      // Load trailers if not already loaded
      if (_latestTrailers.isEmpty) {
        _latestTrailers = await _movieService.getLatestTrailers();
      }
    } catch (e) {
      debugPrint('Error loading movies data: $e');
      throw e;
    }
  }

  Future<void> _loadTvShowsData() async {
    try {
      final results = await Future.wait([
        _tvService.getPopularTvShows(page: _popularTvShowsPage),
        _tvService.getTopRatedTvShows(page: _topRatedTvShowsPage),
        _tvService.getAiringTodayTvShows(page: _airingTodayShowsPage),
        _tvService.getOnTheAirTvShows(page: _onTheAirShowsPage),
      ]);

      _popularTvShows = results[0];
      _topRatedTvShows = results[1];
      _airingTodayShows = results[2];
      _onTheAirShows = results[3];
    } catch (e) {
      debugPrint('Error loading TV shows data: $e');
      throw e;
    }
  }

  // Search methods
  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    _isSearching = false;
    _searchResults = [];
    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _state = MediaListState.loading;
    _currentSearchQuery = query;
    _searchPage = 1;
    _hasMoreSearchResults = true;
    notifyListeners();

    try {
      List<dynamic> results;
      if (_selectedMediaType == MediaType.movie) {
        results = await _movieService.searchMovies(query);
        _searchResults =
            results.map((movie) => MediaItem.fromMovie(movie)).toList();
      } else {
        results = await _tvService.searchTvShows(query);
        _searchResults =
            results.map((show) => MediaItem.fromTvShow(show)).toList();
      }

      _firebaseService.logEvent('search', {
        'query': query,
        'content_type':
            _selectedMediaType == MediaType.movie ? 'movie' : 'tv_show',
        'results_count': _searchResults.length,
        'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      if (!_searchHistory.contains(query)) {
        _searchHistory = [query, ..._searchHistory.take(9)];
      }

      _state = MediaListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = MediaListState.error;

      _firebaseService.logEvent('search_error', {
        'query': query,
        'error': e.toString(),
        'content_type':
            _selectedMediaType == MediaType.movie ? 'movie' : 'tv_show'
      });
    }
    notifyListeners();
  }

  Future<void> loadMoreSearchResults() async {
    if (!_hasMoreSearchResults ||
        _isLoadingMoreSearch ||
        _currentSearchQuery.isEmpty) {
      return;
    }

    _isLoadingMoreSearch = true;
    notifyListeners();

    try {
      List<dynamic> results;
      if (_selectedMediaType == MediaType.movie) {
        results = await _movieService.searchMovies(_currentSearchQuery,
            page: _searchPage + 1);
      } else {
        results = await _tvService.searchTvShows(_currentSearchQuery,
            page: _searchPage + 1);
      }

      if (results.isEmpty) {
        _hasMoreSearchResults = false;
      } else {
        _searchPage++;
        _searchResults.addAll(
          results.map((item) => _selectedMediaType == MediaType.movie
              ? MediaItem.fromMovie(item)
              : MediaItem.fromTvShow(item)),
        );
      }
    } catch (e) {
      debugPrint('Error loading more search results: $e');
    } finally {
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  void clearSearchHistory() {
    _searchHistory = [];
    notifyListeners();
  }

  void updateSearchHistory(List<String> newHistory) {
    _searchHistory = newHistory;
    notifyListeners();
  }

  // Navigation
  void navigateToDetails(BuildContext context, dynamic media) {
    String type = '';
    int id = 0;
    String title = '';

    if (media is Movie) {
      type = 'movie';
      id = media.id;
      title = media.title;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailsScreen(movieId: media.id),
        ),
      );
    } else if (media is TvShow) {
      type = 'tv_show';
      id = media.id;
      title = media.title;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TvShowDetailsScreen(tvShowId: media.id),
        ),
      );
    }

    _firebaseService.logEvent('view_details', {
      'content_type': type,
      'content_id': id,
      'content_title': title,
    });
  }

  Future<void> loadMorePopularMovies() => _loadPopularMovies();
  Future<void> loadMoreTopRatedMovies() => _loadTopRatedMovies();
  Future<void> loadMoreUpcomingMovies() => _loadUpcomingMovies();
  Future<void> loadMorePopularTvShows() => _loadPopularTvShows();
  Future<void> loadMoreTopRatedTvShows() => _loadTopRatedTvShows();
  Future<void> loadMoreAiringTodayShows() => _loadAiringTodayShows();
  Future<void> loadMoreOnTheAirShows() => _loadOnTheAirShows();

  Future<void> refresh() async {
    if (_selectedMediaType == MediaType.movie) {
      _popularMovies.clear();
      _topRatedMovies.clear();
      _upcomingMovies.clear();
      _popularMoviesPage = 1;
      _topRatedMoviesPage = 1;
      _upcomingMoviesPage = 1;
      _hasMorePopularMovies = true;
      _hasMoreTopRatedMovies = true;
      _hasMoreUpcomingMovies = true;
      await _loadMoviesData();
    } else {
      _popularTvShows.clear();
      _topRatedTvShows.clear();
      _airingTodayShows.clear();
      _onTheAirShows.clear();
      _popularTvShowsPage = 1;
      _topRatedTvShowsPage = 1;
      _airingTodayShowsPage = 1;
      _onTheAirShowsPage = 1;
      _hasMorePopularTvShows = true;
      _hasMoreTopRatedTvShows = true;
      _hasMoreAiringTodayShows = true;
      _hasMoreOnTheAirShows = true;
      await _loadTvShowsData();
    }
    notifyListeners();
  }

  Future<void> _loadPopularMovies() async {
    if (!_hasMorePopularMovies || _isLoadingMorePopularMovies) return;
    _isLoadingMorePopularMovies = true;
    notifyListeners();

    try {
      final movies =
          await _movieService.getPopularMovies(page: _popularMoviesPage + 1);
      if (movies.isEmpty) {
        _hasMorePopularMovies = false;
      } else {
        _popularMovies.addAll(movies);
        _popularMoviesPage++;
      }
    } catch (e) {
      debugPrint('Error loading more popular movies: $e');
    } finally {
      _isLoadingMorePopularMovies = false;
      notifyListeners();
    }
  }

  Future<void> _loadTopRatedMovies() async {
    if (!_hasMoreTopRatedMovies || _isLoadingMoreTopRatedMovies) return;
    _isLoadingMoreTopRatedMovies = true;
    notifyListeners();

    try {
      final movies =
          await _movieService.getTopRatedMovies(page: _topRatedMoviesPage + 1);
      if (movies.isEmpty) {
        _hasMoreTopRatedMovies = false;
      } else {
        _topRatedMovies.addAll(movies);
        _topRatedMoviesPage++;
      }
    } catch (e) {
      debugPrint('Error loading more top rated movies: $e');
    } finally {
      _isLoadingMoreTopRatedMovies = false;
      notifyListeners();
    }
  }

  Future<void> _loadUpcomingMovies() async {
    if (!_hasMoreUpcomingMovies || _isLoadingMoreUpcomingMovies) return;
    _isLoadingMoreUpcomingMovies = true;
    notifyListeners();

    try {
      final movies =
          await _movieService.getUpcomingMovies(page: _upcomingMoviesPage + 1);
      if (movies.isEmpty) {
        _hasMoreUpcomingMovies = false;
      } else {
        _upcomingMovies.addAll(movies);
        _upcomingMoviesPage++;
      }
    } catch (e) {
      debugPrint('Error loading more upcoming movies: $e');
    } finally {
      _isLoadingMoreUpcomingMovies = false;
      notifyListeners();
    }
  }

  Future<void> _loadPopularTvShows() async {
    if (!_hasMorePopularTvShows || _isLoadingMorePopularTvShows) return;
    _isLoadingMorePopularTvShows = true;
    notifyListeners();

    try {
      final shows =
          await _tvService.getPopularTvShows(page: _popularTvShowsPage + 1);
      if (shows.isEmpty) {
        _hasMorePopularTvShows = false;
      } else {
        _popularTvShows.addAll(shows);
        _popularTvShowsPage++;
      }
    } catch (e) {
      debugPrint('Error loading more popular TV shows: $e');
    } finally {
      _isLoadingMorePopularTvShows = false;
      notifyListeners();
    }
  }

  Future<void> _loadTopRatedTvShows() async {
    if (!_hasMoreTopRatedTvShows || _isLoadingMoreTopRatedTvShows) return;
    _isLoadingMoreTopRatedTvShows = true;
    notifyListeners();

    try {
      final shows =
          await _tvService.getTopRatedTvShows(page: _topRatedTvShowsPage + 1);
      if (shows.isEmpty) {
        _hasMoreTopRatedTvShows = false;
      } else {
        _topRatedTvShows.addAll(shows);
        _topRatedTvShowsPage++;
      }
    } catch (e) {
      debugPrint('Error loading more top rated TV shows: $e');
    } finally {
      _isLoadingMoreTopRatedTvShows = false;
      notifyListeners();
    }
  }

  Future<void> _loadAiringTodayShows() async {
    if (!_hasMoreAiringTodayShows || _isLoadingMoreAiringTodayTvShows) return;
    _isLoadingMoreAiringTodayTvShows = true;
    notifyListeners();

    try {
      final shows = await _tvService.getAiringTodayTvShows(
          page: _airingTodayShowsPage + 1);
      if (shows.isEmpty) {
        _hasMoreAiringTodayShows = false;
      } else {
        _airingTodayShows.addAll(shows);
        _airingTodayShowsPage++;
      }
    } catch (e) {
      debugPrint('Error loading more airing today shows: $e');
    } finally {
      _isLoadingMoreAiringTodayTvShows = false;
      notifyListeners();
    }
  }

  Future<void> _loadOnTheAirShows() async {
    if (!_hasMoreOnTheAirShows || _isLoadingMoreOnTheAirTvShows) return;
    _isLoadingMoreOnTheAirTvShows = true;
    notifyListeners();

    try {
      final shows =
          await _tvService.getOnTheAirTvShows(page: _onTheAirShowsPage + 1);
      if (shows.isEmpty) {
        _hasMoreOnTheAirShows = false;
      } else {
        _onTheAirShows.addAll(shows);
        _onTheAirShowsPage++;
      }
    } catch (e) {
      debugPrint('Error loading more on the air shows: $e');
    } finally {
      _isLoadingMoreOnTheAirTvShows = false;
      notifyListeners();
    }
  }

  Future<List<MediaItem>> getRecommendationsBasedOnGenres(
    List<int> preferredGenres, {
    int limit = 10,
  }) async {
    try {
      final recommendations = <MediaItem>[];

      // Get recommendations based on media type
      if (_selectedMediaType == MediaType.movie) {
        await Future.wait(
          preferredGenres.map((genreId) async {
            try {
              final movies = await _movieService.getMoviesByGenre(
                genreId,
                page: 1,
              );
              recommendations.addAll(
                movies.map((m) => MediaItem.fromMovie(m)),
              );
            } catch (error) {
              debugPrint('Error fetching movies for genre $genreId: $error');
            }
          }),
        );
      } else {
        await Future.wait(
          preferredGenres.map((genreId) async {
            try {
              final shows = await _tvService.getTvShowsByGenre(
                genreId,
                page: 1,
              );
              recommendations.addAll(
                shows.map((s) => MediaItem.fromTvShow(s)),
              );
            } catch (error) {
              debugPrint('Error fetching TV shows for genre $genreId: $error');
            }
          }),
        );
      }

      // If no recommendations were found, try getting trending content
      if (recommendations.isEmpty) {
        final trending = await getTrendingContent(limit: limit);
        recommendations.addAll(trending);
      }

      recommendations.shuffle();
      return recommendations.take(limit).toList();
    } catch (error) {
      debugPrint('Error getting recommendations: $error');
      return [];
    }
  }

  Future<List<MediaItem>> getTrendingContent({int limit = 10}) async {
    try {
      List<dynamic> trending;
      if (_selectedMediaType == MediaType.movie) {
        trending = await _movieService.getTrendingMovies();
      } else {
        trending = await _tvService.getTrendingTvShows();
      }

      return _selectedMediaType == MediaType.movie
          ? trending.map((m) => MediaItem.fromMovie(m)).take(limit).toList()
          : trending.map((s) => MediaItem.fromTvShow(s)).take(limit).toList();
    } catch (error) {
      debugPrint('Error getting trending content: $error');
      return [];
    }
  }
}
