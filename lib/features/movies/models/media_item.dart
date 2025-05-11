import 'movie.dart';
import 'tv_show.dart';

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
}
