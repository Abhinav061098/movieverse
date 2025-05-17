import 'movie.dart';
import 'tv_show.dart';
import 'package:movieverse/features/movies/models/movie_details.dart';
import 'package:movieverse/features/movies/models/tv_show_details.dart';
import 'package:flutter/foundation.dart';

class MediaItem {
  final dynamic item;
  final int id;

  String get mediaType =>
      item is Movie ? (item as Movie).mediaType : (item as TvShow).mediaType;

  MediaItem(Map<String, dynamic> json)
      : id = (json['id'] as num).toInt(),
        item = json['media_type'] == 'tv'
            ? TvShow.fromJson({
                'id': json['id'],
                'name': json['name'] ?? json['title'],
                'poster_path': json['poster_path'],
                'backdrop_path': json['backdrop_path'],
                'overview': json['overview'],
                'first_air_date':
                    json['first_air_date'] ?? json['release_date'],
                'vote_average': json['vote_average'] is num
                    ? json['vote_average']
                    : (double.tryParse(json['vote_average'].toString()) ?? 0.0),
                'genre_ids': (json['genre_ids'] as List<dynamic>?)
                        ?.map((e) => (e is num) ? e.toInt() : e as int)
                        .toList() ??
                    [],
              })
            : Movie.fromJson({
                'id': json['id'],
                'title': json['title'] ?? json['name'],
                'poster_path': json['poster_path'],
                'backdrop_path': json['backdrop_path'],
                'overview': json['overview'],
                'release_date': json['release_date'] ?? json['first_air_date'],
                'vote_average': json['vote_average'] is num
                    ? json['vote_average']
                    : (double.tryParse(json['vote_average'].toString()) ?? 0.0),
                'genre_ids': (json['genre_ids'] as List<dynamic>?)
                        ?.map((e) => (e is num) ? e.toInt() : e as int)
                        .toList() ??
                    [],
              }) {
    debugPrint(
        'MediaItem: Creating from JSON with id=$id, media_type=${json['media_type']}');
    debugPrint('MediaItem: Fields present: ${json.keys.join(', ')}');
    debugPrint('MediaItem: Created ${item.runtimeType} object');
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(json);
  }

  factory MediaItem.fromMovie(Movie movie) {
    final Map<String, dynamic> json = {
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'backdrop_path': movie.backdropPath,
      'overview': movie.overview,
      'release_date': movie.releaseDate,
      'vote_average': movie.voteAverage,
      'media_type': 'movie',
      'genre_ids': movie.genreIds,
    };
    return MediaItem(json);
  }

  factory MediaItem.fromTvShow(TvShow show) {
    final Map<String, dynamic> json = {
      'id': show.id,
      'name': show.title,
      'poster_path': show.posterPath,
      'backdrop_path': show.backdropPath,
      'overview': show.overview,
      'first_air_date': show.firstAirDate,
      'vote_average': show.voteAverage,
      'media_type': 'tv',
      'genre_ids': show.genreIds,
    };
    return MediaItem(json);
  }

  factory MediaItem.fromMovieDetails(MovieDetails details) {
    final Map<String, dynamic> json = {
      'id': details.id,
      'title': details.title,
      'poster_path': details.posterPath,
      'backdrop_path': details.backdropPath,
      'overview': details.overview,
      'release_date': details.releaseDate,
      'vote_average': details.voteAverage,
      'media_type': 'movie',
      'runtime': details.runtime,
      'genre_ids': details.genres.map((g) => g.id).toList(),
    };
    return MediaItem(json);
  }

  factory MediaItem.fromTvShowDetails(TvShowDetails details) {
    final Map<String, dynamic> json = {
      'id': details.id,
      'name': details.title,
      'poster_path': details.posterPath,
      'backdrop_path': details.backdropPath,
      'overview': details.overview,
      'first_air_date': details.firstAirDate,
      'vote_average': details.voteAverage,
      'media_type': 'tv',
      'number_of_seasons': details.numberOfSeasons,
      'genre_ids': details.genres.map((g) => g.id).toList(),
    };
    return MediaItem(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'media_type': mediaType,
    };

    if (item is Movie) {
      final movie = item as Movie;
      json.addAll({
        'title': movie.title,
        'poster_path': movie.posterPath,
        'backdrop_path': movie.backdropPath,
        'overview': movie.overview,
        'release_date': movie.releaseDate,
        'vote_average': movie.voteAverage,
        'genre_ids': movie.genreIds,
      });
    } else {
      final tvShow = item as TvShow;
      json.addAll({
        'name': tvShow.title,
        'poster_path': tvShow.posterPath,
        'backdrop_path': tvShow.backdropPath,
        'overview': tvShow.overview,
        'first_air_date': tvShow.firstAirDate,
        'vote_average': tvShow.voteAverage,
        'genre_ids': tvShow.genreIds,
      });
    }
    return json;
  }

  String get fullPosterPath => item is Movie
      ? (item as Movie).fullPosterPath
      : (item as TvShow).fullPosterPath;

  double get voteAverage => item is Movie
      ? (item as Movie).voteAverage
      : (item as TvShow).voteAverage;

  String get name =>
      item is Movie ? (item as Movie).title : (item as TvShow).title;

  String get title => name;

  String? get releaseDate => item is Movie
      ? (item as Movie).releaseDate
      : (item as TvShow).firstAirDate;

  String? get firstAirDate => releaseDate;
}
