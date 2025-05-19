import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:movieverse/features/movies/models/genre.dart';
import 'package:movieverse/features/movies/models/video_response.dart';
import '../../../core/api/api_constants.dart';
import 'movie_trailer.dart';
import 'credits.dart';

part 'movie_details.g.dart';

@JsonSerializable()
class MovieDetails extends Equatable {
  final int id;
  final String title;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;
  final String overview;
  @JsonKey(name: 'release_date')
  final String releaseDate;
  @JsonKey(name: 'vote_average')
  final double voteAverage;
  final int runtime;
  final List<Genre> genres;
  final Credits credits;
  @JsonKey(name: 'videos')
  final VideoResponse videos;
  @JsonKey(ignore: true)
  final DateTime? lastUpdated;

  const MovieDetails({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.runtime,
    required this.genres,
    required this.credits,
    required this.videos,
    this.lastUpdated,
  });

  MovieDetails copyWith({
    int? id,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    String? releaseDate,
    double? voteAverage,
    int? runtime,
    List<Genre>? genres,
    Credits? credits,
    VideoResponse? videos,
    DateTime? lastUpdated,
  }) {
    return MovieDetails(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      runtime: runtime ?? this.runtime,
      genres: genres ?? this.genres,
      credits: credits ?? this.credits,
      videos: videos ?? this.videos,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get fullPosterPath =>
      posterPath != null ? ApiConstants.imageUrlOriginal + posterPath! : '';

  String get fullBackdropPath =>
      backdropPath != null ? ApiConstants.imageUrlOriginal + backdropPath! : '';

  String get formattedRuntime {
    final hours = runtime ~/ 60;
    final minutes = runtime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  List<MovieTrailer> get trailers => videos.results
      .where(
        (video) =>
            video.site.toLowerCase() == 'youtube' &&
            video.type.toLowerCase() == 'trailer',
      )
      .toList();

  factory MovieDetails.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$MovieDetailsToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        posterPath,
        backdropPath,
        overview,
        releaseDate,
        voteAverage,
        runtime,
        genres,
        credits,
        videos,
        lastUpdated,
      ];
}
