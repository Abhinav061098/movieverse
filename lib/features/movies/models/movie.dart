import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie extends Equatable {
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
  @JsonKey(name: 'genre_ids')
  final List<int> genreIds;

  const Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
  });

  String get fullPosterPath =>
      posterPath != null ? ApiConstants.imageUrlW500 + posterPath! : '';

  String get fullBackdropPath =>
      backdropPath != null ? ApiConstants.imageUrlOriginal + backdropPath! : '';

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
  Map<String, dynamic> toJson() => _$MovieToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        posterPath,
        backdropPath,
        overview,
        releaseDate,
        voteAverage,
        genreIds,
      ];
}
