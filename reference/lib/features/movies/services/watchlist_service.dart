import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:synchronized/synchronized.dart';
import '../models/watchlist.dart';
import '../models/media_item.dart';

class WatchlistOperationFailedException implements Exception {
  final String message;
  final dynamic originalError;

  WatchlistOperationFailedException(this.message, [this.originalError]);

  @override
  String toString() =>
      'WatchlistOperationFailedException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class WatchlistService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, Watchlist> _localCache = {};
  final _watchlistsController = StreamController<List<Watchlist>>.broadcast();
  StreamSubscription<DatabaseEvent>? _watchlistsSub;
  StreamSubscription<User?>? _authSub;
  bool _isDisposed = false;
  final _operationLock = Lock();
  final _firebaseService =
      FirebaseService(); // Assuming FirebaseService is defined elsewhere

  Stream<List<Watchlist>> get watchlistsStream => _watchlistsController.stream;
  List<Watchlist> get watchlists => _localCache.values.toList();

  WatchlistService._();

  static Future<WatchlistService> create() async {
    final service = WatchlistService._();
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;

    try {
      debugPrint('WatchlistService: Initializing...');
      await _database.keepSynced(true);

      final currentUser = _auth.currentUser;
      debugPrint('WatchlistService: Current user at init: ${currentUser?.uid}');

      _authSub?.cancel();
      _authSub = _auth.authStateChanges().listen((user) async {
        if (_isDisposed) return;

        debugPrint('WatchlistService: Auth state changed. User: ${user?.uid}');
        if (user != null) {
          debugPrint(
              'WatchlistService: User authenticated, loading watchlists...');
          await _loadWatchlists();
          _setupRealtimeSync();
        } else {
          debugPrint('WatchlistService: No user logged in, clearing cache');
          _localCache.clear();
          _watchlistsSub?.cancel();
          _notifyListeners();
        }
      }, onError: (error) {
        debugPrint('WatchlistService: Error in auth state changes: $error');
      });

      // Initialize immediately if user is already logged in
      if (currentUser != null) {
        await _loadWatchlists();
        _setupRealtimeSync();
      }
    } catch (e) {
      debugPrint('WatchlistService: Error initializing service: $e');
    }
  }

  void _setupRealtimeSync() {
    if (_isDisposed) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('WatchlistService: Cannot setup sync - no user logged in');
      return;
    }

    debugPrint('WatchlistService: Setting up realtime sync for user $userId');
    _watchlistsSub?.cancel();
    _watchlistsSub = _database.child('watchlists/$userId').onValue.listen(
      (event) {
        if (_isDisposed) return;
        debugPrint('\n============ WATCHLIST SYNC EVENT ============');
        debugPrint('WatchlistService: Received database update event');

        try {
          if (event.snapshot.value == null) {
            debugPrint('WatchlistService: No watchlists data in Firebase');
            _localCache.clear();
            _notifyListeners();
            return;
          }

          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          debugPrint('\nProcessing ${data.length} watchlists from Firebase');

          // Create a new map for atomic update
          final newCache = <String, Watchlist>{};

          // Process each watchlist
          data.forEach((key, value) {
            try {
              if (value == null) {
                debugPrint('Watchlist $key is null, skipping');
                return;
              }

              final watchlistData = Map<String, dynamic>.from(value as Map);
              debugPrint(
                  '\nProcessing watchlist: ${watchlistData['name']} ($key)');

              // Handle items
              if (watchlistData.containsKey('items') &&
                  watchlistData['items'] != null) {
                debugPrint('Found items in watchlist $key');
                final itemsMap = watchlistData['items'] as Map;
                final processedItems = <String, dynamic>{};

                itemsMap.forEach((itemKey, itemValue) {
                  try {
                    if (itemValue != null) {
                      final itemData =
                          Map<String, dynamic>.from(itemValue as Map);
                      processedItems[itemKey.toString()] = itemData;
                      debugPrint('Successfully processed item: $itemKey');
                    }
                  } catch (e) {
                    debugPrint('Error processing item $itemKey: $e');
                  }
                });

                watchlistData['items'] = processedItems;
                debugPrint(
                    'Processed ${processedItems.length} items for watchlist $key');
              } else {
                watchlistData['items'] = <String, dynamic>{};
                debugPrint('No items found in watchlist $key');
              }

              // Create watchlist object
              final watchlist = Watchlist.fromJson(key, watchlistData);
              newCache[key] = watchlist;
              debugPrint(
                  'Added watchlist to cache: ${watchlist.name} with ${watchlist.items.length} items');
            } catch (e) {
              debugPrint('Error processing watchlist $key: $e');
            }
          });

          // Update cache atomically
          _localCache.clear();
          _localCache.addAll(newCache);
          debugPrint('\nCache updated with ${_localCache.length} watchlists');
          _notifyListeners();
        } catch (e) {
          debugPrint('Error in realtime sync: $e');
        }
      },
      onError: (error) {
        debugPrint('Error in realtime sync: $error');
      },
    );
  }

  Future<void> _loadWatchlists() async {
    if (_isDisposed) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('WatchlistService: No user ID available');
        return;
      }

      debugPrint('\n=== LOADING WATCHLISTS ===');
      debugPrint('Loading watchlists for user: $userId');

      final snapshot = await _database.child('watchlists/$userId').get();
      debugPrint('Firebase snapshot exists: ${snapshot.exists}');

      if (snapshot.exists) {
        debugPrint('\nRaw Firebase Data:');
        debugPrint(snapshot.value.toString());
      }

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('No data in Firebase, clearing cache');
        _localCache.clear();
        _notifyListeners();
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      debugPrint('\nProcessing watchlists:');
      data.forEach((key, value) {
        final watchlistData = Map<String, dynamic>.from(value as Map);
        debugPrint('\nWatchlist: ${watchlistData['name']} ($key)');
        if (watchlistData.containsKey('items')) {
          final items = watchlistData['items'] as Map?;
          debugPrint('Items count in raw data: ${items?.length ?? 0}');
          if (items != null && items.isNotEmpty) {
            debugPrint('First item raw data: ${items.values.first}');
          }
        } else {
          debugPrint('No items key found in watchlist data');
        }
      });

      _localCache.clear();

      // Process watchlists
      await Future.forEach(data.entries,
          (MapEntry<String, dynamic> entry) async {
        try {
          final watchlistData = Map<String, dynamic>.from(entry.value as Map);
          if (!watchlistData.containsKey('items')) {
            watchlistData['items'] = {};
          }
          final watchlist = Watchlist.fromJson(entry.key, watchlistData);
          _localCache[entry.key] = watchlist;
        } catch (e, stackTrace) {
          debugPrint('Error loading watchlist ${entry.key}: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      });

      debugPrint('\nFinal cache state:');
      _localCache.forEach((key, watchlist) {
        debugPrint(
            'Watchlist ${watchlist.name}: ${watchlist.items.length} items');
      });

      _notifyListeners();
    } catch (e) {
      debugPrint('Error loading watchlists: $e');
    }
  }

  Future<Watchlist> createWatchlist(String name, String description) async {
    return await _operationLock.synchronized(() async {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          throw WatchlistOperationFailedException('User not logged in');
        }

        final watchlistRef = _database.child('watchlists/$userId').push();
        final watchlistId = watchlistRef.key!;
        final watchlist = Watchlist(
          id: watchlistId,
          name: name,
          description: description,
          createdAt: DateTime.now(),
          items: {},
        );

        await watchlistRef.set(watchlist.toJson());
        debugPrint(
            'WatchlistService: Successfully created watchlist $watchlistId');

        // Log watchlist creation
        _firebaseService.logEvent('create_watchlist', {
          'watchlist_id': watchlistId,
          'watchlist_name': name,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Update local cache immediately
        _localCache[watchlistId] = watchlist;
        _notifyListeners();

        return watchlist;
      } catch (e) {
        debugPrint('WatchlistService: Error creating watchlist: $e');
        _firebaseService.logEvent('watchlist_error', {
          'action': 'create',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        throw WatchlistOperationFailedException(
            'Failed to create watchlist', e);
      }
    });
  }

  Future<void> addToWatchlist(String watchlistId, MediaItem mediaItem) async {
    await _operationLock.synchronized(() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw WatchlistOperationFailedException('User not logged in');
      }

      try {
        final itemId = '${mediaItem.item.mediaType}_${mediaItem.item.id}';
        final itemData = {
          'id': mediaItem.item.id,
          'media_type': mediaItem.item.mediaType,
          'poster_path': mediaItem.item.posterPath,
          'backdrop_path': mediaItem.item.backdropPath,
          'overview': mediaItem.item.overview,
          'vote_average': mediaItem.item.voteAverage,
          'genre_ids': mediaItem.item.genreIds,
          'added_at': DateTime.now().toIso8601String(),
        };

        // Add media type specific fields
        if (mediaItem.item.mediaType == 'tv') {
          itemData['name'] = mediaItem.name;
          itemData['first_air_date'] = mediaItem.firstAirDate;
        } else {
          itemData['title'] = mediaItem.title;
          itemData['release_date'] = mediaItem.releaseDate;
        }

        debugPrint(
            'WatchlistService: Adding item to watchlist with data: $itemData');

        await _database
            .child('watchlists/$userId/$watchlistId/items/$itemId')
            .set(itemData);

        debugPrint('WatchlistService: Successfully saved item to Firebase');
        await _loadWatchlists();
        debugPrint('WatchlistService: Reloaded watchlists after adding item');
      } catch (e) {
        debugPrint('WatchlistService: Error adding item to watchlist: $e');
        throw WatchlistOperationFailedException(
            'Failed to add item to watchlist: ${e.toString()}');
      }
    });
  }

  Future<void> removeFromWatchlist(String watchlistId, String itemId) async {
    await _operationLock.synchronized(() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw WatchlistOperationFailedException('User not logged in');
      }

      try {
        debugPrint(
            'WatchlistService: Removing item $itemId from watchlist $watchlistId');

        // Remove from Firebase first
        await _database
            .child('watchlists/$userId/$watchlistId/items/$itemId')
            .remove();

        // Update local cache immediately for smooth UI
        if (_localCache.containsKey(watchlistId)) {
          final watchlist = _localCache[watchlistId]!;
          final updatedItems = Map<String, WatchlistItem>.from(watchlist.items);
          updatedItems.remove(itemId);

          _localCache[watchlistId] = Watchlist(
            id: watchlist.id,
            name: watchlist.name,
            description: watchlist.description,
            createdAt: watchlist.createdAt,
            items: updatedItems,
          );

          // Notify listeners after local cache update
          _notifyListeners();
        }

        // Log successful removal
        _firebaseService.logEvent('remove_from_watchlist', {
          'watchlist_id': watchlistId,
          'item_id': itemId,
          'timestamp': DateTime.now().toIso8601String(),
        });

        debugPrint(
            'WatchlistService: Successfully removed item from watchlist');
      } catch (e) {
        debugPrint('WatchlistService: Error removing item: $e');
        throw WatchlistOperationFailedException(
            'Failed to remove item: ${e.toString()}');
      }
    });
  }

  Future<void> deleteWatchlist(String watchlistId) async {
    await _operationLock.synchronized(() async {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw WatchlistOperationFailedException('User not logged in');
      }

      try {
        await _database.child('watchlists/$userId/$watchlistId').remove();

        // Log watchlist deletion
        _firebaseService.logEvent('delete_watchlist', {
          'watchlist_id': watchlistId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _firebaseService.logEvent('watchlist_error', {
          'action': 'delete',
          'watchlist_id': watchlistId,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        });
        throw WatchlistOperationFailedException(
            'Failed to delete watchlist', e);
      }
    });
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      final currentWatchlists = watchlists;
      notifyListeners();
      if (!_watchlistsController.isClosed) {
        _watchlistsController.add(currentWatchlists);
      }
      debugPrint(
          'WatchlistService: Notified listeners with ${currentWatchlists.length} watchlists');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _watchlistsSub?.cancel();
    _authSub?.cancel();
    _watchlistsController.close();
    super.dispose();
  }
}
