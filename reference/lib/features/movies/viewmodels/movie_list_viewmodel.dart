import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/movie_trailer.dart';
import '../services/movie_service.dart';

enum MovieListState { initial, loading, loaded, error }

class MovieListViewModel with ChangeNotifier {
  final MovieService _movieService;
  MovieListState _state = MovieListState.initial;
  String _error = '';
  final List<Movie> _popularMovies = [];
  final List<Movie> _topRatedMovies = [];
  final List<Movie> _upcomingMovies = [];
  List<MovieTrailer> _latestTrailers = [];
  int _popularPage = 1;
  int _topRatedPage = 1;
  int _upcomingPage = 1;
  bool _hasMorePopular = true;
  bool _hasMoreTopRated = true;
  bool _hasMoreUpcoming = true;

  MovieListViewModel(this._movieService);

  MovieListState get state => _state;
  String get error => _error;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<MovieTrailer> get latestTrailers => _latestTrailers;
  bool get hasMorePopular => _hasMorePopular;
  bool get hasMoreTopRated => _hasMoreTopRated;
  bool get hasMoreUpcoming => _hasMoreUpcoming;

  Future<void> loadInitialData() async {
    _state = MovieListState.loading;
    notifyListeners();

    try {
      await Future.wait([
        _loadLatestTrailers(),
        _loadPopularMovies(),
        _loadTopRatedMovies(),
        _loadUpcomingMovies(),
      ]);
      _state = MovieListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
    }
    notifyListeners();
  }

  Future<void> _loadLatestTrailers() async {
    try {
      _latestTrailers = await _movieService.getLatestTrailers();
    } catch (e) {
      print('Error loading trailers: $e');
      // Don't set error state for trailers, just log it
    }
  }

  Future<void> _loadPopularMovies() async {
    if (!_hasMorePopular) return;

    try {
      final movies = await _movieService.getPopularMovies(page: _popularPage);
      if (movies.isEmpty) {
        _hasMorePopular = false;
      } else {
        _popularMovies.addAll(movies);
        _popularPage++;
      }
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
    }
  }

  Future<void> _loadTopRatedMovies() async {
    if (!_hasMoreTopRated) return;

    try {
      final movies = await _movieService.getTopRatedMovies(page: _topRatedPage);
      if (movies.isEmpty) {
        _hasMoreTopRated = false;
      } else {
        _topRatedMovies.addAll(movies);
        _topRatedPage++;
      }
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
    }
  }

  Future<void> _loadUpcomingMovies() async {
    if (!_hasMoreUpcoming) return;

    try {
      final movies = await _movieService.getUpcomingMovies(page: _upcomingPage);
      if (movies.isEmpty) {
        _hasMoreUpcoming = false;
      } else {
        _upcomingMovies.addAll(movies);
        _upcomingPage++;
      }
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
    }
  }

  Future<void> loadMorePopular() => _loadPopularMovies();
  Future<void> loadMoreTopRated() => _loadTopRatedMovies();
  Future<void> loadMoreUpcoming() => _loadUpcomingMovies();

  Future<void> refresh() async {
    _popularMovies.clear();
    _topRatedMovies.clear();
    _upcomingMovies.clear();
    _latestTrailers.clear();
    _popularPage = 1;
    _topRatedPage = 1;
    _upcomingPage = 1;
    _hasMorePopular = true;
    _hasMoreTopRated = true;
    _hasMoreUpcoming = true;
    await loadInitialData();
  }
}
