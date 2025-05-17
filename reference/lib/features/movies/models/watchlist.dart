import 'package:flutter/material.dart';

import '../models/media_item.dart';

class WatchlistItem {
  final MediaItem item;
  final DateTime addedAt;

  WatchlistItem(this.item, this.addedAt);

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    debugPrint('WatchlistItem: Parsing raw data: $json');

    final mediaType = json['media_type'] as String;
    final mediaItemData = <String, dynamic>{
      'id': json['id'],
      'media_type': mediaType,
      'poster_path': json['poster_path'],
      'backdrop_path': json['backdrop_path'],
      'overview': json['overview'],
      'vote_average': json['vote_average'],
      'genre_ids': json['genre_ids'] is List ? json['genre_ids'] : [],
    };

    // Handle fields based on media type
    if (mediaType == 'tv') {
      mediaItemData['name'] = json['name']; // Use name for TV shows
      mediaItemData['first_air_date'] = json['first_air_date'];
      mediaItemData['title'] =
          json['name']; // Set title as name for compatibility
    } else {
      mediaItemData['title'] = json['title']; // Use title for movies
      mediaItemData['release_date'] = json['release_date'];
      mediaItemData['name'] =
          json['title']; // Set name as title for compatibility
    }

    debugPrint('WatchlistItem: Processed media item data: $mediaItemData');

    try {
      final mediaItem = MediaItem(mediaItemData);
      final addedAt = DateTime.parse(json['added_at'] as String);
      debugPrint('WatchlistItem: Successfully created WatchlistItem');
      return WatchlistItem(mediaItem, addedAt);
    } catch (e, stack) {
      debugPrint('WatchlistItem: Error creating MediaItem: $e');
      debugPrint('WatchlistItem: Stack trace: $stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final mediaType = item.mediaType;
    final Map<String, dynamic> json = {
      'id': item.id,
      'media_type': mediaType,
      'poster_path': item.item.posterPath,
      'backdrop_path': item.item.backdropPath,
      'overview': item.item.overview,
      'vote_average': item.item.voteAverage,
      'genre_ids': item.item.genreIds,
      'added_at': addedAt.toIso8601String(),
    };

    // Add media type specific fields
    if (mediaType == 'tv') {
      json['name'] = item.name;
      json['first_air_date'] = item.firstAirDate;
    } else {
      json['title'] = item.title;
      json['release_date'] = item.releaseDate;
    }

    return json;
  }
}

class Watchlist {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final Map<String, WatchlistItem> items;

  Watchlist({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.items,
  });

  factory Watchlist.fromJson(String id, Map<String, dynamic> json) {
    debugPrint('\n=== PARSING WATCHLIST $id ===');
    debugPrint('Raw watchlist data: $json');
    Map<String, WatchlistItem> items = {};

    try {
      final itemsJson = json['items'] as Map<dynamic, dynamic>? ?? {};
      debugPrint('Raw items data type: ${itemsJson.runtimeType}');
      debugPrint('Raw items data: $itemsJson');

      itemsJson.forEach((key, value) {
        try {
          debugPrint('\nProcessing item with key: $key');
          debugPrint('Item value type: ${value.runtimeType}');
          debugPrint('Item raw data: $value');

          if (value is Map) {
            final itemData = Map<String, dynamic>.from(value);
            items[key.toString()] = WatchlistItem.fromJson(itemData);
            debugPrint('Successfully parsed item $key');
          } else {
            debugPrint('Invalid item data format for key $key: $value');
          }
        } catch (e, stack) {
          debugPrint('Error parsing item $key: $e');
          debugPrint('Stack trace: $stack');
        }
      });

      debugPrint('\nFinished parsing items:');
      debugPrint('- Total items parsed: ${items.length}');
      if (items.isNotEmpty) {
        debugPrint('- First item example: ${items.values.first.toJson()}');
      }
    } catch (e, stack) {
      debugPrint('Error parsing items for watchlist $id: $e');
      debugPrint('Stack trace: $stack');
    }

    return Watchlist(
      id: id,
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
