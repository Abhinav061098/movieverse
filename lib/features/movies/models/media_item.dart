import 'movie.dart';
import 'tv_show.dart';
import 'movie_details.dart';
import 'tv_show_details.dart';

class MediaItem {
  final dynamic item;
  final String mediaType;
  final int id;

  MediaItem(Map<String, dynamic> json)
      : id = json['id'],
        mediaType = json['media_type'],
        item = json['media_type'] == 'movie'
            ? Movie.fromJson(json)
            : TvShow.fromJson(json);

  factory MediaItem.fromJson(Map<String, dynamic> json) {
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
    if (item is Movie) {
      final movieJson = (item as Movie).toJson();
      movieJson['media_type'] = 'movie';
      return movieJson;
    } else {
      final tvShowJson = (item as TvShow).toJson();
      tvShowJson['media_type'] = 'tv';
      return tvShowJson;
    }
  }

  String get fullPosterPath => item is Movie
      ? (item as Movie).fullPosterPath
      : (item as TvShow).fullPosterPath;

  double get voteAverage => item is Movie
      ? (item as Movie).voteAverage
      : (item as TvShow).voteAverage;

  String get title =>
      item is Movie ? (item as Movie).title : (item as TvShow).title;

  String get name =>
      item is Movie ? (item as Movie).title : (item as TvShow).title;

  String? get releaseDate => item is Movie
      ? (item as Movie).releaseDate
      : (item as TvShow).firstAirDate;

  String? get firstAirDate => releaseDate;
}
