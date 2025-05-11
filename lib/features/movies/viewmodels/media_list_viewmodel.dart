import 'package:flutter/foundation.dart';
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

// This file is now deprecated. Use movie_view_model.dart and tv_show_view_model.dart instead.

// MediaListViewModel is deprecated.

enum MediaListState { initial, loading, loaded, error }

enum MediaType { movie, tvShow }

class MediaListViewModel with ChangeNotifier {
  final MovieService _movieService;
  final TvService _tvService;
  final FirebaseService _firebaseService = FirebaseService();
  MediaListState _state = MediaListState.initial;
  String _error = '';
  MediaType _selectedMediaType = MediaType.movie;

  // Movies
  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];

  // Pagination for Movies
  int _popularMoviesPage = 1;
  int _topRatedMoviesPage = 1;
  int _upcomingMoviesPage = 1;
  bool _hasMorePopularMovies = true;
  bool _hasMoreTopRatedMovies = true;
  bool _hasMoreUpcomingMovies = true;
  bool _isLoadingMorePopularMovies = false;
  bool _isLoadingMoreTopRatedMovies = false;
  bool _isLoadingMoreUpcomingMovies = false;

  // TV Shows
  List<TvShow> _popularTvShows = [];
  List<TvShow> _topRatedTvShows = [];
  List<TvShow> _airingTodayShows = [];
  List<TvShow> _onTheAirShows = [];

  // Pagination for TV Shows
  int _popularTvShowsPage = 1;
  int _topRatedTvShowsPage = 1;
  int _airingTodayShowsPage = 1;
  int _onTheAirShowsPage = 1;
  bool _hasMorePopularTvShows = true;
  bool _hasMoreTopRatedTvShows = true;
  bool _hasMoreAiringTodayShows = true;
  bool _hasMoreOnTheAirShows = true;
  bool _isLoadingMorePopularTvShows = false;
  bool _isLoadingMoreTopRatedTvShows = false;
  bool _isLoadingMoreAiringTodayShows = false;
  bool _isLoadingMoreOnTheAirShows = false;

  // Search Results
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  List<String> _searchHistory = [];

  // Search pagination
  int _searchPage = 1;
  bool _hasMoreSearchResults = true;
  bool _isLoadingMoreSearch = false;

  List<MovieTrailer> _latestTrailers = [];

  MovieDetails? _movieOfTheDay;

  MediaListViewModel(this._movieService, this._tvService);

  // Getters
  MediaListState get state => _state;
  String get error => _error;
  MediaType get selectedMediaType => _selectedMediaType;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  List<dynamic> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;

  // Movie getters
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;

  // TV Show getters
  List<TvShow> get popularTvShows => _popularTvShows;
  List<TvShow> get topRatedTvShows => _topRatedTvShows;
  List<TvShow> get airingTodayShows => _airingTodayShows;
  List<TvShow> get onTheAirShows => _onTheAirShows;

  List<MovieTrailer> get latestTrailers => _latestTrailers;

  bool get isLoadingMoreSearch => _isLoadingMoreSearch;

  MovieDetails? get movieOfTheDay => _movieOfTheDay;

  // Methods
  void setMediaType(MediaType type) {
    _selectedMediaType = type;
    // Clear search results when switching media types
    _searchResults = [];
    _searchPage = 1;
    _hasMoreSearchResults = true;
    _isLoadingMoreSearch = false;

    _firebaseService.logEvent('switch_media_type',
        {'type': type == MediaType.movie ? 'movie' : 'tv_show'});

    // Re-run search if there's an active query
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }

  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  void stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    _searchResults = [];
    _searchPage = 1;
    _hasMoreSearchResults = true;
    _isLoadingMoreSearch = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _searchPage = 1;
    _hasMoreSearchResults = true;
    _state = MediaListState.loading;
    notifyListeners();

    try {
      if (_selectedMediaType == MediaType.movie) {
        final results = await _movieService.searchMovies(query);
        _searchResults =
            results.map((movie) => MediaItem(movie.toJson())).toList();
      } else {
        final results = await _tvService.searchTvShows(query);
        _searchResults =
            results.map((show) => MediaItem(show.toJson())).toList();
      }

      _firebaseService.logEvent('search', {
        'query': query,
        'content_type':
            _selectedMediaType == MediaType.movie ? 'movie' : 'tv_show',
        'results_count': _searchResults.length,
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
      });
    }
    notifyListeners();
  }

  Future<void> loadMoreSearchResults() async {
    if (!_hasMoreSearchResults || _isLoadingMoreSearch || _searchQuery.isEmpty)
      return;

    _isLoadingMoreSearch = true;
    notifyListeners();

    try {
      if (_selectedMediaType == MediaType.movie) {
        final results = await _movieService.searchMovies(
          _searchQuery,
          page: _searchPage + 1,
        );
        if (results.isEmpty) {
          _hasMoreSearchResults = false;
        } else {
          _searchResults
              .addAll(results.map((movie) => MediaItem(movie.toJson())));
          _searchPage++;
        }
      } else {
        final results = await _tvService.searchTvShows(
          _searchQuery,
          page: _searchPage + 1,
        );
        if (results.isEmpty) {
          _hasMoreSearchResults = false;
        } else {
          _searchResults
              .addAll(results.map((show) => MediaItem(show.toJson())));
          _searchPage++;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  void clearSearchHistory() {
    _searchHistory = [];
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _state = MediaListState.loading;
    notifyListeners();

    try {
      await Future.wait([
        _loadMovieOfTheDay(),
        _loadMovieData(),
        _loadTvShowData(),
        _loadLatestTrailers(),
      ]);
      _state = MediaListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = MediaListState.error;
    }
    notifyListeners();
  }

  Future<void> _loadMovieData() async {
    final futures = await Future.wait([
      _movieService.getPopularMovies(),
      _movieService.getTopRatedMovies(),
      _movieService.getUpcomingMovies(),
    ]);

    _popularMovies = futures[0];
    _topRatedMovies = futures[1];
    _upcomingMovies = futures[2];
  }

  Future<void> _loadTvShowData() async {
    final futures = await Future.wait([
      _tvService.getPopularTvShows(),
      _tvService.getTopRatedTvShows(),
      _tvService.getAiringTodayTvShows(),
      _tvService.getOnTheAirTvShows(),
    ]);

    _popularTvShows = futures[0];
    _topRatedTvShows = futures[1];
    _airingTodayShows = futures[2];
    _onTheAirShows = futures[3];
  }

  Future<void> _loadLatestTrailers() async {
    try {
      _latestTrailers = await _movieService.getLatestTrailers();
    } catch (e) {
      print('Error loading trailers: $e');
      _latestTrailers = [];
    }
  }

  Future<void> _loadMovieOfTheDay() async {
    try {
      _movieOfTheDay = await _movieService.getMovieOfTheDay();
    } catch (e) {
      print('Error loading movie of the day: $e');
    }
  }

  Future<void> refresh() async {
    _popularMovies = [];
    _topRatedMovies = [];
    _upcomingMovies = [];
    _popularTvShows = [];
    _topRatedTvShows = [];
    _airingTodayShows = [];
    _onTheAirShows = [];
    _latestTrailers = [];
    _searchResults = [];

    // Reset pagination states
    _popularMoviesPage = 1;
    _topRatedMoviesPage = 1;
    _upcomingMoviesPage = 1;
    _hasMorePopularMovies = true;
    _hasMoreTopRatedMovies = true;
    _hasMoreUpcomingMovies = true;
    _isLoadingMorePopularMovies = false;
    _isLoadingMoreTopRatedMovies = false;
    _isLoadingMoreUpcomingMovies = false;

    _popularTvShowsPage = 1;
    _topRatedTvShowsPage = 1;
    _airingTodayShowsPage = 1;
    _onTheAirShowsPage = 1;
    _hasMorePopularTvShows = true;
    _hasMoreTopRatedTvShows = true;
    _hasMoreAiringTodayShows = true;
    _hasMoreOnTheAirShows = true;
    _isLoadingMorePopularTvShows = false;
    _isLoadingMoreTopRatedTvShows = false;
    _isLoadingMoreAiringTodayShows = false;
    _isLoadingMoreOnTheAirShows = false;

    _searchPage = 1;
    _hasMoreSearchResults = true;
    _isLoadingMoreSearch = false;

    notifyListeners();
    await loadInitialData();
  }

  Future<void> loadMorePopularMovies() async {
    if (!_hasMorePopularMovies || _isLoadingMorePopularMovies) return;

    _isLoadingMorePopularMovies = true;
    notifyListeners();

    try {
      final movies = await _movieService.getPopularMovies(
        page: _popularMoviesPage + 1,
      );
      if (movies.isEmpty) {
        _hasMorePopularMovies = false;
      } else {
        _popularMovies.addAll(movies);
        _popularMoviesPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMorePopularMovies = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTopRatedMovies() async {
    if (!_hasMoreTopRatedMovies || _isLoadingMoreTopRatedMovies) return;

    _isLoadingMoreTopRatedMovies = true;
    notifyListeners();

    try {
      final movies = await _movieService.getTopRatedMovies(
        page: _topRatedMoviesPage + 1,
      );
      if (movies.isEmpty) {
        _hasMoreTopRatedMovies = false;
      } else {
        _topRatedMovies.addAll(movies);
        _topRatedMoviesPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreTopRatedMovies = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreUpcomingMovies() async {
    if (!_hasMoreUpcomingMovies || _isLoadingMoreUpcomingMovies) return;

    _isLoadingMoreUpcomingMovies = true;
    notifyListeners();

    try {
      final movies = await _movieService.getUpcomingMovies(
        page: _upcomingMoviesPage + 1,
      );
      if (movies.isEmpty) {
        _hasMoreUpcomingMovies = false;
      } else {
        _upcomingMovies.addAll(movies);
        _upcomingMoviesPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreUpcomingMovies = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePopularTvShows() async {
    if (!_hasMorePopularTvShows || _isLoadingMorePopularTvShows) return;

    _isLoadingMorePopularTvShows = true;
    notifyListeners();

    try {
      final shows = await _tvService.getPopularTvShows(
        page: _popularTvShowsPage + 1,
      );
      if (shows.isEmpty) {
        _hasMorePopularTvShows = false;
      } else {
        _popularTvShows.addAll(shows);
        _popularTvShowsPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMorePopularTvShows = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTopRatedTvShows() async {
    if (!_hasMoreTopRatedTvShows || _isLoadingMoreTopRatedTvShows) return;

    _isLoadingMoreTopRatedTvShows = true;
    notifyListeners();

    try {
      final shows = await _tvService.getTopRatedTvShows(
        page: _topRatedTvShowsPage + 1,
      );
      if (shows.isEmpty) {
        _hasMoreTopRatedTvShows = false;
      } else {
        _topRatedTvShows.addAll(shows);
        _topRatedTvShowsPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreTopRatedTvShows = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAiringTodayShows() async {
    if (!_hasMoreAiringTodayShows || _isLoadingMoreAiringTodayShows) return;

    _isLoadingMoreAiringTodayShows = true;
    notifyListeners();

    try {
      final shows = await _tvService.getAiringTodayTvShows(
        page: _airingTodayShowsPage + 1,
      );
      if (shows.isEmpty) {
        _hasMoreAiringTodayShows = false;
      } else {
        _airingTodayShows.addAll(shows);
        _airingTodayShowsPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreAiringTodayShows = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOnTheAirShows() async {
    if (!_hasMoreOnTheAirShows || _isLoadingMoreOnTheAirShows) return;

    _isLoadingMoreOnTheAirShows = true;
    notifyListeners();

    try {
      final shows = await _tvService.getOnTheAirTvShows(
        page: _onTheAirShowsPage + 1,
      );
      if (shows.isEmpty) {
        _hasMoreOnTheAirShows = false;
      } else {
        _onTheAirShows.addAll(shows);
        _onTheAirShowsPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMoreOnTheAirShows = false;
      notifyListeners();
    }
  }

  // Add pagination getters
  bool get isLoadingMorePopularMovies => _isLoadingMorePopularMovies;
  bool get isLoadingMoreTopRatedMovies => _isLoadingMoreTopRatedMovies;
  bool get isLoadingMoreUpcomingMovies => _isLoadingMoreUpcomingMovies;
  bool get hasMorePopularMovies => _hasMorePopularMovies;
  bool get hasMoreTopRatedMovies => _hasMoreTopRatedMovies;
  bool get hasMoreUpcomingMovies => _hasMoreUpcomingMovies;

  bool get isLoadingMorePopularTvShows => _isLoadingMorePopularTvShows;
  bool get isLoadingMoreTopRatedTvShows => _isLoadingMoreTopRatedTvShows;
  bool get isLoadingMoreAiringTodayShows => _isLoadingMoreAiringTodayShows;
  bool get isLoadingMoreOnTheAirShows => _isLoadingMoreOnTheAirShows;
  bool get hasMorePopularTvShows => _hasMorePopularTvShows;
  bool get hasMoreTopRatedTvShows => _hasMoreTopRatedTvShows;
  bool get hasMoreAiringTodayShows => _hasMoreAiringTodayShows;
  bool get hasMoreOnTheAirShows => _hasMoreOnTheAirShows;

  void updateSearchHistory(List<String> newHistory) {
    _searchHistory = newHistory;
    notifyListeners();
  }

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
}
