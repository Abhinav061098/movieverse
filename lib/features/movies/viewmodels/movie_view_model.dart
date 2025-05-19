import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/movie_trailer.dart';
import '../models/movie_details.dart';
import '../models/genre.dart';
import '../models/director.dart';
import '../services/movie_service.dart';
import '../services/director_service.dart';

enum MovieListState { initial, loading, loaded, error }

class MovieViewModel with ChangeNotifier {
  final MovieService _movieService;
  final DirectorService _directorService;
  MovieListState _state = MovieListState.initial;
  String _error = '';

  List<Movie> _popularMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _upcomingMovies = [];
  List<MovieTrailer> _latestTrailers = [];
  MovieDetails? _movieOfTheDay;
  List<Genre> _genres = [];
  List<Director> _popularDirectors = [];
  int? _selectedGenreId;

  int _popularMoviesPage = 1;
  int _topRatedMoviesPage = 1;
  int _upcomingMoviesPage = 1;
  int _directorsPage = 1;
  static const int _directorsPerPage = 15;
  bool _hasMorePopularMovies = true;
  bool _hasMoreTopRatedMovies = true;
  bool _hasMoreUpcomingMovies = true;
  bool _hasMoreDirectors = true;
  bool _isLoadingMorePopularMovies = false;
  bool _isLoadingMoreTopRatedMovies = false;
  bool _isLoadingMoreUpcomingMovies = false;
  bool _isLoadingMoreDirectors = false;
  bool _isLoading = false;

  MovieViewModel(this._movieService, this._directorService);

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
  List<Director> get popularDirectors => _popularDirectors;

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
  bool get isLoadingMoreDirectors => _isLoadingMoreDirectors;
  bool get hasMorePopularMovies => _hasMorePopularMovies;
  bool get hasMoreTopRatedMovies => _hasMoreTopRatedMovies;
  bool get hasMoreUpcomingMovies => _hasMoreUpcomingMovies;
  bool get hasMoreDirectors => _hasMoreDirectors;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _state = MovieListState.loading;
    notifyListeners();
    try {
      // Load movie of the day and movie data in parallel
      final movieDataFutures = await Future.wait([
        _loadMovieOfTheDay(),
        _loadMovieData(),
        _loadLatestTrailers(),
        fetchGenres(),
      ]);

      // Start loading directors immediately after getting movie data
      _loadPopularDirectors();

      _state = MovieListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = MovieListState.error;
      debugPrint('Error in loadInitialData: $e');
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
      // Check if we have a cached movie of the day from today
      final now = DateTime.now();
      if (_movieOfTheDay != null &&
          _movieOfTheDay!.lastUpdated != null &&
          _movieOfTheDay!.lastUpdated!.year == now.year &&
          _movieOfTheDay!.lastUpdated!.month == now.month &&
          _movieOfTheDay!.lastUpdated!.day == now.day) {
        return;
      }
      final movie = await _movieService.getMovieOfTheDay();
      _movieOfTheDay = movie.copyWith(lastUpdated: now);
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
    _directorsPage = 1;
    _hasMorePopularMovies = true;
    _hasMoreTopRatedMovies = true;
    _hasMoreUpcomingMovies = true;
    _hasMoreDirectors = true;
    _isLoadingMorePopularMovies = false;
    _isLoadingMoreTopRatedMovies = false;
    _isLoadingMoreUpcomingMovies = false;
    _isLoadingMoreDirectors = false;
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

  Future<void> _loadPopularDirectors({bool reset = false}) async {
    if (reset) {
      _directorsPage = 1;
      _popularDirectors = [];
      _hasMoreDirectors = true;
    }
    if (_isLoadingMoreDirectors || !_hasMoreDirectors) return;
    _isLoadingMoreDirectors = true;
    debugPrint('Loading directors page: $_directorsPage');

    // Create a map of unique movies
    final moviesMap = <int, Movie>{};
    for (var movie in _popularMovies.take(_directorsPerPage * _directorsPage)) {
      moviesMap[movie.id] = movie;
    }
    for (var movie
        in _topRatedMovies.take(_directorsPerPage * _directorsPage)) {
      moviesMap[movie.id] = movie;
    }
    for (var movie
        in _upcomingMovies.take(_directorsPerPage * _directorsPage)) {
      moviesMap[movie.id] = movie;
    }

    final allMovies = moviesMap.values.toList();
    if (allMovies.isEmpty) {
      debugPrint('No movies available to fetch directors');
      _isLoadingMoreDirectors = false;
      return;
    }

    // Load directors for all movies in parallel
    final directorFutures = allMovies.map((movie) async {
      try {
        return await _directorService.getMovieDirectors(movie.id);
      } catch (e) {
        debugPrint('Error fetching directors for movie ${movie.title}: $e');
        return <Director>[];
      }
    });

    final directorsResults = await Future.wait(directorFutures);
    final directors =
        directorsResults.expand((directors) => directors).toList();

    final uniqueDirectors = directors
        .fold<Map<int, Director>>({}, (map, dir) {
          if (!map.containsKey(dir.id)) {
            map[dir.id] = dir;
          }
          return map;
        })
        .values
        .toList();

    final previousCount = _popularDirectors.length;
    _popularDirectors =
        uniqueDirectors.take(_directorsPerPage * _directorsPage).toList();
    _hasMoreDirectors = _popularDirectors.length > previousCount;
    _isLoadingMoreDirectors = false;
    notifyListeners();
  }

  Future<void> loadMoreDirectors() async {
    if (_isLoadingMoreDirectors || !_hasMoreDirectors) return;
    _directorsPage++;
    await _loadPopularDirectors();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
