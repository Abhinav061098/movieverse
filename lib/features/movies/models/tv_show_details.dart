import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';
import 'genre.dart';
import 'credits.dart';
import 'video_response.dart';
import 'season.dart';
import 'movie_trailer.dart';
import 'external_ids.dart';

part 'tv_show_details.g.dart';

@JsonSerializable()
class TvShowDetails extends Equatable {
  final int id;
  @JsonKey(name: 'name')
  final String title;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;
  final String overview;
  @JsonKey(name: 'first_air_date')
  final String firstAirDate;
  @JsonKey(name: 'vote_average')
  final double voteAverage;
  @JsonKey(name: 'number_of_seasons')
  final int numberOfSeasons;
  final List<Genre> genres;
  final Credits credits;
  @JsonKey(name: 'videos')
  final VideoResponse videos;
  @JsonKey(name: 'seasons')
  final List<Season> seasons;
  @JsonKey(name: 'external_ids')
  final ExternalIds? externalIds;
  final String? homepage;

  const TvShowDetails({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.firstAirDate,
    required this.voteAverage,
    required this.numberOfSeasons,
    required this.genres,
    required this.credits,
    required this.videos,
    required this.seasons,
    this.externalIds,
    this.homepage,
  });

  String get fullPosterPath =>
      posterPath != null ? ApiConstants.imageUrlOriginal + posterPath! : '';

  String get fullBackdropPath =>
      backdropPath != null ? ApiConstants.imageUrlOriginal + backdropPath! : '';

  List<MovieTrailer> get trailers => videos.results
      .where(
        (video) =>
            video.site.toLowerCase() == 'youtube' &&
            video.type.toLowerCase() == 'trailer',
      )
      .toList();

  factory TvShowDetails.fromJson(Map<String, dynamic> json) =>
      _$TvShowDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$TvShowDetailsToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        posterPath,
        backdropPath,
        overview,
        firstAirDate,
        voteAverage,
        numberOfSeasons,
        genres,
        credits,
        videos,
        seasons,
        externalIds,
        homepage,
      ];
}
