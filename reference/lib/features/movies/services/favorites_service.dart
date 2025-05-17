import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:synchronized/synchronized.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/movie_details.dart';
import '../models/tv_show_details.dart';

class FavoriteOperationFailedException implements Exception {
  final String message;
  final dynamic originalError;

  FavoriteOperationFailedException(this.message, [this.originalError]);

  @override
  String toString() =>
      'FavoriteOperationFailedException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class FavoritesService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, MediaItem> _localCache = {};
  final _favoritesController = StreamController<List<MediaItem>>.broadcast();
  StreamSubscription<DatabaseEvent>? _favoritesSub;
  StreamSubscription<User?>? _authSub;
  bool _isDisposed = false;
  final _operationLock = Lock();
  final _firebaseService = FirebaseService();

  static Future<FavoritesService> create() async {
    final service = FavoritesService();
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;

    try {
      debugPrint('FavoritesService: Initializing...');
      await _database.keepSynced(true);

      final currentUser = _auth.currentUser;
      debugPrint('FavoritesService: Current user at init: ${currentUser?.uid}');

      _authSub = _auth.authStateChanges().listen((user) {
        if (_isDisposed) return;

        debugPrint('FavoritesService: Auth state changed. User: ${user?.uid}');
        if (user != null) {
          debugPrint(
              'FavoritesService: User authenticated, loading favorites...');
          _loadFavorites();
          _setupRealtimeSync();
        } else {
          debugPrint('FavoritesService: No user logged in, clearing cache');
          _localCache.clear();
          _notifyListeners();
        }
      }, onError: (error) {
        debugPrint('FavoritesService: Error in auth state changes: $error');
      });
    } catch (e) {
      debugPrint('FavoritesService: Error initializing service: $e');
    }
  }

  void _setupRealtimeSync() {
    if (_isDisposed) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('FavoritesService: Cannot setup sync - no user logged in');
      return;
    }

    debugPrint('FavoritesService: Setting up realtime sync for user $userId');
    _favoritesSub?.cancel();
    _favoritesSub = _database.child('favorites/$userId').onValue.listen(
      (event) {
        if (_isDisposed) return;
        debugPrint('FavoritesService: Received database update event');

        if (event.snapshot.value == null) {
          debugPrint('FavoritesService: No favorites data in Firebase');
          _localCache.clear();
          _notifyListeners();
          return;
        }

        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          debugPrint(
              'FavoritesService: Processing ${data.length} favorites from Firebase');

          _localCache.clear();
          data.forEach((key, value) {
            try {
              final itemData = Map<String, dynamic>.from(value as Map);
              final mediaItem = MediaItem(itemData);
              _localCache[key] = mediaItem;
              debugPrint('FavoritesService: Processed favorite item $key');
            } catch (e) {
              debugPrint(
                  'FavoritesService: Error processing favorite item $key: $e');
            }
          });

          _notifyListeners();
        } catch (e) {
          debugPrint('FavoritesService: Error processing favorites update: $e');
        }
      },
      onError: (error) {
        debugPrint('FavoritesService: Error in realtime sync: $error');
      },
    );
  }

  Future<void> _loadFavorites() async {
    if (_isDisposed) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint(
            'FavoritesService: Cannot load favorites - no user logged in');
        _localCache.clear();
        _notifyListeners();
        return;
      }

      debugPrint('FavoritesService: Loading favorites for user: $userId');
      final snapshot = await _database.child('favorites/$userId').get();

      _localCache.clear();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          try {
            final itemData = Map<String, dynamic>.from(value as Map);
            final mediaItem = MediaItem(itemData);
            _localCache[key] = mediaItem;
          } catch (e) {
            debugPrint(
                'FavoritesService: Error processing favorite item $key: $e');
          }
        });
      }

      _notifyListeners();
    } catch (e) {
      debugPrint('FavoritesService: Error loading favorites: $e');
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      final favorites = _localCache.values.toList();
      notifyListeners();
      if (!_favoritesController.isClosed) {
        _favoritesController.add(favorites);
      }
    }
  }

  List<MediaItem> get currentFavorites => _localCache.values.toList();

  Stream<List<MediaItem>> get favoritesStream => _favoritesController.stream;

  Future<bool> toggleMovieFavorite(int movieId,
      {required MovieDetails details}) async {
    return await _operationLock.synchronized(() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final itemId = 'movie_$movieId';
      final isFavorite = _localCache.containsKey(itemId);

      try {
        if (isFavorite) {
          await _database.child('favorites/$userId/$itemId').remove();
          _localCache.remove(itemId);
          _notifyListeners();

          _firebaseService.logEvent('remove_favorite', {
            'content_type': 'movie',
            'content_id': movieId.toString(),
            'content_title': details.title,
            'timestamp': DateTime.now().toIso8601String(),
          });

          return false;
        } else {
          final mediaItem = MediaItem.fromMovieDetails(details);
          await _database
              .child('favorites/$userId/$itemId')
              .set(mediaItem.toJson());
          _localCache[itemId] = mediaItem;
          _notifyListeners();

          _firebaseService.logEvent('add_favorite', {
            'content_type': 'movie',
            'content_id': movieId.toString(),
            'content_title': details.title,
            'genres': details.genres.map((g) => g.name).join(','),
            'rating': details.voteAverage.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          });

          return true;
        }
      } catch (e, stack) {
        debugPrint('Error toggling movie favorite: $e\n$stack');
        rethrow;
      }
    });
  }

  Future<bool> toggleTvShowFavorite(int tvShowId,
      {required TvShowDetails details}) async {
    return await _operationLock.synchronized(() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final itemId = 'tv_$tvShowId';
      final isFavorite = _localCache.containsKey(itemId);

      try {
        if (isFavorite) {
          await _database.child('favorites/$userId/$itemId').remove();
          _localCache.remove(itemId);
          _notifyListeners();

          _firebaseService.logEvent('remove_favorite', {
            'content_type': 'tv_show',
            'content_id': tvShowId.toString(),
            'content_title': details.title,
            'timestamp': DateTime.now().toIso8601String(),
          });

          return false;
        } else {
          final mediaItem = MediaItem.fromTvShowDetails(details);
          await _database
              .child('favorites/$userId/$itemId')
              .set(mediaItem.toJson());
          _localCache[itemId] = mediaItem;
          _notifyListeners();

          _firebaseService.logEvent('add_favorite', {
            'content_type': 'tv_show',
            'content_id': tvShowId.toString(),
            'content_title': details.title,
            'genres': details.genres.map((g) => g.name).join(','),
            'rating': details.voteAverage.toString(),
            'number_of_seasons': details.numberOfSeasons.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          });

          return true;
        }
      } catch (e, stack) {
        debugPrint('Error toggling tv show favorite: $e\n$stack');
        rethrow;
      }
    });
  }

  bool isMovieFavorite(int movieId) {
    return _localCache.containsKey('movie_$movieId');
  }

  bool isTvShowFavorite(int tvShowId) {
    return _localCache.containsKey('tv_$tvShowId');
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;
    await _favoritesSub?.cancel();
    await _authSub?.cancel();
    await _favoritesController.close();
    super.dispose();
  }
}
