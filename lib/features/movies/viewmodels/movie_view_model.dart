import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/movie_trailer.dart';
import '../models/movie_details.dart';
import '../models/genre.dart';
import '../services/movie_service.dart';

enum MovieListState { initial, loading, loaded, error }

class MovieViewModel with ChangeNotifier {
  final MovieService _movieService;
  MovieListState _state = MovieListState.initial;
  String _error = '';

  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];
  List<MovieTrailer> _latestTrailers = [];
  MovieDetails? _movieOfTheDay;
  List<Genre> _genres = [];
  int? _selectedGenreId;

  int _popularMoviesPage = 1;
  int _topRatedMoviesPage = 1;
  int _upcomingMoviesPage = 1;
  bool _hasMorePopularMovies = true;
  bool _hasMoreTopRatedMovies = true;
  bool _hasMoreUpcomingMovies = true;
  bool _isLoadingMorePopularMovies = false;
  bool _isLoadingMoreTopRatedMovies = false;
  bool _isLoadingMoreUpcomingMovies = false;

  MovieViewModel(this._movieService);

  MovieListState get state => _state;
  String get error => _error;
  List<Movie> get popularMovies => _popularMovies;
  List<Movie> get topRatedMovies => _topRatedMovies;
  List<Movie> get upcomingMovies => _upcomingMovies;
  List<MovieTrailer> get latestTrailers => _latestTrailers;
  List<MovieTrailer> get trailers => _latestTrailers;
  MovieDetails? get movieOfTheDay => _movieOfTheDay;
  List<Genre> get genres => _genres;
  int? get selectedGenreId => _selectedGenreId;

  List<Movie> get filteredPopularMovies => _selectedGenreId == null
      ? _popularMovies
      : _popularMovies
          .where((m) => m.genreIds.contains(_selectedGenreId))
          .toList();
  List<Movie> get filteredTopRatedMovies => _selectedGenreId == null
      ? _topRatedMovies
      : _topRatedMovies
          .where((m) => m.genreIds.contains(_selectedGenreId))
          .toList();
  List<Movie> get filteredUpcomingMovies => _selectedGenreId == null
      ? _upcomingMovies
      : _upcomingMovies
          .where((m) => m.genreIds.contains(_selectedGenreId))
          .toList();

  bool get isLoadingMorePopularMovies => _isLoadingMorePopularMovies;
  bool get isLoadingMoreTopRatedMovies => _isLoadingMoreTopRatedMovies;
  bool get isLoadingMoreUpcomingMovies => _isLoadingMoreUpcomingMovies;
  bool get hasMorePopularMovies => _hasMorePopularMovies;
  bool get hasMoreTopRatedMovies => _hasMoreTopRatedMovies;
  bool get hasMoreUpcomingMovies => _hasMoreUpcomingMovies;

  Future<void> loadInitialData() async {
    _state = MovieListState.loading;
    notifyListeners();
    try {
      await Future.wait([
        _loadMovieOfTheDay(),
        _loadMovieData(),
        _loadLatestTrailers(),
        fetchGenres(),
      ]);
      _state = MovieListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
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

  Future<void> _loadLatestTrailers() async {
    try {
      _latestTrailers = await _movieService.getLatestTrailers();
    } catch (e) {
      _latestTrailers = [];
    }
  }

  Future<void> _loadMovieOfTheDay() async {
    try {
      _movieOfTheDay = await _movieService.getMovieOfTheDay();
    } catch (e) {
      // ignore error
    }
  }

  Future<void> fetchGenres() async {
    try {
      _genres = await _movieService.getGenres();
      notifyListeners();
    } catch (e) {
      // ignore genre errors
    }
  }

  void setSelectedGenre(int? genreId) {
    _selectedGenreId = genreId;
    notifyListeners();
  }

  Future<void> refresh() async {
    _popularMovies = [];
    _topRatedMovies = [];
    _upcomingMovies = [];
    _latestTrailers = [];
    _popularMoviesPage = 1;
    _topRatedMoviesPage = 1;
    _upcomingMoviesPage = 1;
    _hasMorePopularMovies = true;
    _hasMoreTopRatedMovies = true;
    _hasMoreUpcomingMovies = true;
    _isLoadingMorePopularMovies = false;
    _isLoadingMoreTopRatedMovies = false;
    _isLoadingMoreUpcomingMovies = false;
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
}
