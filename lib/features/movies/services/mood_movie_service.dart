import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/mood_movie_data.dart';
import 'package:movieverse/features/movies/services/watchlist_service.dart';
import 'package:movieverse/features/movies/services/favorites_service.dart';
import 'package:movieverse/features/movies/models/movie.dart';

class MoodMovieService {
  final ApiClient _apiClient;
  late final WatchlistService _watchlistService;
  late final FavoritesService _favoritesService;
  bool _isInitialized = false;

  MoodMovieService(this._apiClient);

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('\n=== INITIALIZING MOOD MOVIE SERVICE ===');
      _watchlistService = await WatchlistService.create();
      debugPrint('WatchlistService initialized');

      _favoritesService = FavoritesService();
      debugPrint('FavoritesService initialized');

      _isInitialized = true;
      debugPrint('MoodMovieService initialization complete');
    } catch (e, stackTrace) {
      debugPrint('Error initializing MoodMovieService: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<MoodMovieData> getMoodMovieData() async {
    try {
      debugPrint('\n=== MOOD MOVIE DATA ANALYSIS ===');

      // Ensure services are initialized
      await _initialize();

      // Get user's watchlist and favorites
      final watchlists = _watchlistService.watchlists;
      final favorites = _favoritesService.currentFavorites;

      debugPrint('\nUser Data Summary:');
      debugPrint('Number of watchlists: ${watchlists.length}');
      debugPrint('Number of favorites: ${favorites.length}');

      if (watchlists.isEmpty && favorites.isEmpty) {
        debugPrint('No watchlists or favorites found');
        return MoodMovieData(
          moodGenres: {},
          genreCounts: {},
          timeBasedPreferences: {},
          movies: [],
        );
      }

      // Combine and analyze genres from both lists
      final genreCounts = <String, int>{};
      final movies = <Movie>[];

      // Analyze watchlist and favorites to build genre counts
      for (final watchlist in watchlists) {
        debugPrint('\nProcessing watchlist: ${watchlist.name}');
        debugPrint('Items in watchlist: ${watchlist.items.length}');

        for (final item in watchlist.items.values) {
          if (item.item.item.genreIds.isNotEmpty) {
            movies.add(item.item.item);
            for (final genreId in item.item.item.genreIds) {
              final genre = _getGenreName(genreId);
              genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
              debugPrint('Added genre from watchlist: $genre (ID: $genreId)');
            }
          } else {
            debugPrint('Warning: Movie ${item.item.item.title} has no genres');
          }
        }
      }

      for (final favorite in favorites) {
        debugPrint('\nProcessing favorite: ${favorite.title}');
        if (favorite.item is Movie && favorite.item.genreIds.isNotEmpty) {
          movies.add(favorite.item as Movie);
          for (final genreId in favorite.item.genreIds) {
            final genre = _getGenreName(genreId);
            genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
            debugPrint('Added genre from favorite: $genre (ID: $genreId)');
          }
        } else {
          debugPrint('Warning: Skipping non-movie favorite: ${favorite.title}');
        }
      }

      debugPrint('\nFinal genre counts:');
      genreCounts.forEach((genre, count) {
        debugPrint('$genre: $count');
      });

      debugPrint('\nTotal movies collected: ${movies.length}');

      if (genreCounts.isEmpty) {
        debugPrint('Warning: No genre data collected');
      }

      return MoodMovieData(
        moodGenres: _calculateMoodGenres(genreCounts),
        genreCounts: genreCounts,
        timeBasedPreferences: _calculateTimeBasedPreferences(genreCounts),
        movies: movies,
      );
    } catch (e, stackTrace) {
      debugPrint('Error in getMoodMovieData: $e');
      debugPrint('Stack trace: $stackTrace');
      return MoodMovieData(
        moodGenres: {},
        genreCounts: {},
        timeBasedPreferences: {},
        movies: [],
      );
    }
  }

  String _getGenreName(int genreId) {
    // Map genre IDs to names
    switch (genreId) {
      case 28:
        return 'Action';
      case 12:
        return 'Adventure';
      case 16:
        return 'Animation';
      case 35:
        return 'Comedy';
      case 80:
        return 'Crime';
      case 99:
        return 'Documentary';
      case 18:
        return 'Drama';
      case 10751:
        return 'Family';
      case 14:
        return 'Fantasy';
      case 36:
        return 'History';
      case 27:
        return 'Horror';
      case 10402:
        return 'Music';
      case 9648:
        return 'Mystery';
      case 10749:
        return 'Romance';
      case 878:
        return 'Sci-Fi';
      case 10770:
        return 'TV Movie';
      case 53:
        return 'Thriller';
      case 10752:
        return 'War';
      case 37:
        return 'Western';
      default:
        return 'Unknown';
    }
  }

  Future<void> updateMoodData(String mood, String genre) async {
    // TODO: Implement saving mood and genre data
    // 1. Save to local storage
    // 2. Update analytics
    // 3. Sync with backend if needed
  }

  Future<void> updateTimeBasedPreference(String time, String genre) async {
    // TODO: Implement saving time-based preferences
    // 1. Save to local storage
    // 2. Update analytics
    // 3. Sync with backend if needed
  }

  Map<String, String> _calculateTimeBasedPreferences(
      Map<String, int> genreCounts) {
    final timeBasedPreferences = <String, String>{};

    // Get all watchlist items and their added times
    final watchTimes = <String, List<DateTime>>{};

    // Collect watch times from watchlists
    for (final watchlist in _watchlistService.watchlists) {
      for (final item in watchlist.items.values) {
        final genre = _getGenreName(item.item.item.genreIds.first);
        if (!watchTimes.containsKey(genre)) {
          watchTimes[genre] = [];
        }
        watchTimes[genre]!.add(item.addedAt);
      }
    }

    // Collect watch times from favorites
    for (final favorite in _favoritesService.currentFavorites) {
      final genre = _getGenreName(favorite.item.genreIds.first);
      if (!watchTimes.containsKey(genre)) {
        watchTimes[genre] = [];
      }
      // For favorites, we'll use the current time as a proxy
      watchTimes[genre]!.add(DateTime.now());
    }

    // Calculate time-based preferences based on actual watch times
    final morningGenres = <String, int>{};
    final afternoonGenres = <String, int>{};
    final eveningGenres = <String, int>{};
    final nightGenres = <String, int>{};

    watchTimes.forEach((genre, times) {
      for (final time in times) {
        final hour = time.hour;
        if (hour >= 5 && hour < 12) {
          morningGenres[genre] = (morningGenres[genre] ?? 0) + 1;
        } else if (hour >= 12 && hour < 17) {
          afternoonGenres[genre] = (afternoonGenres[genre] ?? 0) + 1;
        } else if (hour >= 17 && hour < 22) {
          eveningGenres[genre] = (eveningGenres[genre] ?? 0) + 1;
        } else {
          nightGenres[genre] = (nightGenres[genre] ?? 0) + 1;
        }
      }
    });

    // Get top genres for each time period
    String getTopGenres(Map<String, int> genreCounts) {
      final sorted = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(2).map((e) => e.key).join(' & ');
    }

    // Assign preferences if we have data
    if (morningGenres.isNotEmpty) {
      timeBasedPreferences['Morning'] = getTopGenres(morningGenres);
    }
    if (afternoonGenres.isNotEmpty) {
      timeBasedPreferences['Afternoon'] = getTopGenres(afternoonGenres);
    }
    if (eveningGenres.isNotEmpty) {
      timeBasedPreferences['Evening'] = getTopGenres(eveningGenres);
    }
    if (nightGenres.isNotEmpty) {
      timeBasedPreferences['Night'] = getTopGenres(nightGenres);
    }

    // If any time period is empty, use genre counts as fallback
    if (timeBasedPreferences.isEmpty) {
      final sortedEntries = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final allGenres = sortedEntries.map((e) => e.key).toList();

      if (allGenres.isNotEmpty) {
        timeBasedPreferences['Morning'] = allGenres.take(2).join(' & ');
        if (allGenres.length > 2) {
          timeBasedPreferences['Afternoon'] =
              allGenres.skip(2).take(2).join(' & ');
        }
        if (allGenres.length > 4) {
          timeBasedPreferences['Evening'] =
              allGenres.skip(4).take(2).join(' & ');
        }
        if (allGenres.length > 6) {
          timeBasedPreferences['Night'] = allGenres.skip(6).take(2).join(' & ');
        }
      }
    }

    return timeBasedPreferences;
  }

  Map<String, List<String>> _calculateMoodGenres(Map<String, int> genreCounts) {
    final moodGenres = <String, List<String>>{};

    // Define mood-genre associations with weights
    final moodGenreMap = <String, Map<String, Map<String, double>>>{
      'Happy': {
        'primary': <String, double>{
          'Comedy': 1.5,
          'Animation': 1.3,
          'Family': 1.2,
          'Music': 1.1,
        },
        'secondary': <String, double>{
          'Romance': 0.8,
          'Adventure': 0.7,
          'Fantasy': 0.6,
        },
      },
      'Excited': {
        'primary': <String, double>{
          'Action': 1.5,
          'Adventure': 1.3,
          'Sci-Fi': 1.2,
        },
        'secondary': <String, double>{
          'Fantasy': 0.8,
          'Thriller': 0.7,
          'Crime': 0.6,
        },
      },
      'Relaxed': {
        'primary': <String, double>{
          'Drama': 1.5,
          'Documentary': 1.3,
          'Romance': 1.2,
        },
        'secondary': <String, double>{
          'Comedy': 0.8,
          'Family': 0.7,
          'Music': 0.6,
        },
      },
      'Thoughtful': {
        'primary': <String, double>{
          'Drama': 1.5,
          'Documentary': 1.3,
          'History': 1.2,
        },
        'secondary': <String, double>{
          'Biography': 0.8,
          'War': 0.7,
          'Mystery': 0.6,
        },
      },
      'Thrilled': {
        'primary': <String, double>{
          'Horror': 1.5,
          'Thriller': 1.3,
          'Mystery': 1.2,
        },
        'secondary': <String, double>{
          'Action': 0.8,
          'Crime': 0.7,
          'Sci-Fi': 0.6,
        },
      }
    };

    // Calculate weighted scores for each mood
    final moodScores = <String, Map<String, double>>{};

    // Process watchlist items
    for (final watchlist in _watchlistService.watchlists) {
      for (final item in watchlist.items.values) {
        final genres = item.item.item.genreIds.map(_getGenreName).toList();
        final rating = item.item.item.voteAverage;

        for (final mood in moodGenreMap.entries) {
          if (!moodScores.containsKey(mood.key)) {
            moodScores[mood.key] = {};
          }

          for (final genre in genres) {
            double weight = 0;
            if (mood.value['primary']!.containsKey(genre)) {
              weight = mood.value['primary']![genre]!;
            } else if (mood.value['secondary']!.containsKey(genre)) {
              weight = mood.value['secondary']![genre]!;
            }

            if (weight > 0) {
              final score = weight * (rating / 10); // Normalize rating
              moodScores[mood.key]![genre] =
                  (moodScores[mood.key]![genre] ?? 0) + score;
            }
          }
        }
      }
    }

    // Process favorites
    for (final favorite in _favoritesService.currentFavorites) {
      final genres = favorite.item.genreIds.map(_getGenreName).toList();
      final rating = favorite.item.voteAverage;

      for (final mood in moodGenreMap.entries) {
        if (!moodScores.containsKey(mood.key)) {
          moodScores[mood.key] = {};
        }

        for (final genre in genres) {
          double weight = 0;
          if (mood.value['primary']!.containsKey(genre)) {
            weight = mood.value['primary']![genre]!;
          } else if (mood.value['secondary']!.containsKey(genre)) {
            weight = mood.value['secondary']![genre]!;
          }

          if (weight > 0) {
            final score = weight * (rating / 10); // Normalize rating
            moodScores[mood.key]![genre] =
                (moodScores[mood.key]![genre] ?? 0) + score;
          }
        }
      }
    }

    // Get top genres for each mood based on scores
    for (final mood in moodScores.entries) {
      final sortedGenres = mood.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedGenres.isNotEmpty) {
        moodGenres[mood.key] = sortedGenres.take(3).map((e) => e.key).toList();
      }
    }

    // If no moods have genres, use most watched genres
    if (moodGenres.isEmpty) {
      final sortedGenres = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Distribute top genres across moods
      final topGenres = sortedGenres.take(6).map((e) => e.key).toList();
      if (topGenres.isNotEmpty) {
        moodGenres['Happy'] = topGenres.take(2).toList();
        if (topGenres.length > 2) {
          moodGenres['Excited'] = topGenres.skip(2).take(2).toList();
        }
        if (topGenres.length > 4) {
          moodGenres['Relaxed'] = topGenres.skip(4).take(2).toList();
        }
      }
    }

    return moodGenres;
  }
}
