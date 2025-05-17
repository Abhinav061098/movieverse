import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';

part 'tv_show.g.dart';

@JsonSerializable()
class TvShow extends Equatable {
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
  @JsonKey(name: 'genre_ids')
  final List<int> genreIds;
  @JsonKey(ignore: true)
  final String mediaType = 'tv';

  const TvShow({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.firstAirDate,
    required this.voteAverage,
    required this.genreIds,
  });

  String get fullPosterPath =>
      posterPath != null ? ApiConstants.imageUrlW500 + posterPath! : '';

  String get fullBackdropPath =>
      backdropPath != null ? ApiConstants.imageUrlOriginal + backdropPath! : '';

  factory TvShow.fromJson(Map<String, dynamic> json) => _$TvShowFromJson(json);
  Map<String, dynamic> toJson() => _$TvShowToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    posterPath,
    backdropPath,
    overview,
    firstAirDate,
    voteAverage,
    genreIds,
  ];
}
