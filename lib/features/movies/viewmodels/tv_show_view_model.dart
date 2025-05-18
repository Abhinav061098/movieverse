import 'package:flutter/foundation.dart';
import '../models/tv_show.dart';
import '../models/director.dart';
import '../services/tv_service.dart';
import '../services/director_service.dart';
import '../models/genre.dart';

enum TvShowListState { initial, loading, loaded, error }

class TvShowViewModel with ChangeNotifier {
  final TvService _tvService;
  final DirectorService _directorService;
  TvShowListState _state = TvShowListState.initial;
  String _error = '';

  List<TvShow> _popularTvShows = [];
  List<TvShow> _topRatedTvShows = [];
  List<TvShow> _airingTodayShows = [];
  List<TvShow> _onTheAirShows = [];
  List<Genre> _genres = [];
  List<Director> _popularDirectors = [];
  int? _selectedGenreId;

  int _popularTvShowsPage = 1;
  int _topRatedTvShowsPage = 1;
  int _airingTodayShowsPage = 1;
  int _onTheAirShowsPage = 1;
  int _directorsPage = 1;
  static const int _directorsPerPage = 15;
  bool _hasMorePopularTvShows = true;
  bool _hasMoreTopRatedTvShows = true;
  bool _hasMoreAiringTodayShows = true;
  bool _hasMoreOnTheAirShows = true;
  bool _hasMoreDirectors = true;
  bool _isLoadingMorePopularTvShows = false;
  bool _isLoadingMoreTopRatedTvShows = false;
  bool _isLoadingMoreAiringTodayShows = false;
  bool _isLoadingMoreOnTheAirShows = false;
  bool _isLoadingMoreDirectors = false;

  TvShowViewModel(this._tvService, this._directorService);

  TvShowListState get state => _state;
  String get error => _error;
  List<TvShow> get popularTvShows => _popularTvShows;
  List<TvShow> get topRatedTvShows => _topRatedTvShows;
  List<TvShow> get airingTodayShows => _airingTodayShows;
  List<TvShow> get onTheAirShows => _onTheAirShows;
  List<Genre> get genres => _genres;
  int? get selectedGenreId => _selectedGenreId;

  bool get isLoadingMorePopularTvShows => _isLoadingMorePopularTvShows;
  bool get isLoadingMoreTopRatedTvShows => _isLoadingMoreTopRatedTvShows;
  bool get isLoadingMoreAiringTodayShows => _isLoadingMoreAiringTodayShows;
  bool get isLoadingMoreOnTheAirShows => _isLoadingMoreOnTheAirShows;
  bool get isLoadingMoreDirectors => _isLoadingMoreDirectors;

  List<TvShow> get filteredPopularTvShows => _selectedGenreId == null
      ? _popularTvShows
      : _popularTvShows
          .where((t) => t.genreIds.contains(_selectedGenreId))
          .toList();
  List<TvShow> get filteredTopRatedTvShows => _selectedGenreId == null
      ? _topRatedTvShows
      : _topRatedTvShows
          .where((t) => t.genreIds.contains(_selectedGenreId))
          .toList();
  List<TvShow> get filteredAiringTodayShows => _selectedGenreId == null
      ? _airingTodayShows
      : _airingTodayShows
          .where((t) => t.genreIds.contains(_selectedGenreId))
          .toList();
  List<TvShow> get filteredOnTheAirShows => _selectedGenreId == null
      ? _onTheAirShows
      : _onTheAirShows
          .where((t) => t.genreIds.contains(_selectedGenreId))
          .toList();

  List<Director> get popularDirectors => _popularDirectors;

  Future<void> loadPopularDirectors({bool reset = false}) async {
    if (reset) {
      _directorsPage = 1;
      _popularDirectors = [];
      _hasMoreDirectors = true;
    }
    if (_isLoadingMoreDirectors || !_hasMoreDirectors) return;
    _isLoadingMoreDirectors = true;
    debugPrint('Loading directors page: \\$_directorsPage');
    final directors = <Director>[];
    final showsMap = <int, dynamic>{};
    for (var show in _popularTvShows.take(_directorsPerPage * _directorsPage)) {
      showsMap[show.id] = show;
    }
    for (var show
        in _topRatedTvShows.take(_directorsPerPage * _directorsPage)) {
      showsMap[show.id] = show;
    }
    for (var show
        in _airingTodayShows.take(_directorsPerPage * _directorsPage)) {
      showsMap[show.id] = show;
    }
    for (var show in _onTheAirShows.take(_directorsPerPage * _directorsPage)) {
      showsMap[show.id] = show;
    }
    final allShows = showsMap.values.toList();
    if (allShows.isEmpty) {
      debugPrint('No TV shows available to fetch directors');
      _isLoadingMoreDirectors = false;
      return;
    }
    for (var show in allShows) {
      final showDirectors = await _directorService.getTvShowDirectors(show.id);
      directors.addAll(showDirectors);
    }
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

  Future<void> loadInitialData() async {
    _state = TvShowListState.loading;
    notifyListeners();
    try {
      await _loadTvShowData();
      await fetchGenres();
      await loadPopularDirectors();
      _state = TvShowListState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = TvShowListState.error;
    }
    notifyListeners();
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

  Future<void> fetchGenres() async {
    try {
      _genres = await _tvService.getGenres();
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
    _popularTvShows = [];
    _topRatedTvShows = [];
    _airingTodayShows = [];
    _onTheAirShows = [];
    _popularTvShowsPage = 1;
    _topRatedTvShowsPage = 1;
    _airingTodayShowsPage = 1;
    _onTheAirShowsPage = 1;
    _directorsPage = 1;
    _hasMorePopularTvShows = true;
    _hasMoreTopRatedTvShows = true;
    _hasMoreAiringTodayShows = true;
    _hasMoreOnTheAirShows = true;
    _hasMoreDirectors = true;
    _isLoadingMorePopularTvShows = false;
    _isLoadingMoreTopRatedTvShows = false;
    _isLoadingMoreAiringTodayShows = false;
    _isLoadingMoreOnTheAirShows = false;
    _isLoadingMoreDirectors = false;
    notifyListeners();
    await loadInitialData();
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

  Future<void> loadMoreDirectors() async {
    if (_isLoadingMoreDirectors || !_hasMoreDirectors) return;
    _directorsPage++;
    await loadPopularDirectors();
  }
}
