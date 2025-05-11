import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';
import 'episode.dart';

part 'season.g.dart';

@JsonSerializable()
class Season extends Equatable {
  @JsonKey(name: 'id', defaultValue: 0)
  final int id;
  @JsonKey(name: 'season_number', defaultValue: 0)
  final int seasonNumber;
  @JsonKey(name: 'name')
  final String title;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'overview', defaultValue: '')
  final String overview;
  @JsonKey(name: 'air_date')
  final String? airDate;
  @JsonKey(name: 'episode_count', defaultValue: 0)
  final int episodeCount;
  @JsonKey(includeIfNull: false)
  final List<Episode>? episodes;

  const Season({
    required this.id,
    required this.seasonNumber,
    required this.title,
    this.posterPath,
    required this.overview,
    this.airDate,
    required this.episodeCount,
    this.episodes,
  });

  String get fullPosterPath =>
      posterPath != null ? ApiConstants.imageUrlW500 + posterPath! : '';

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);

  @override
  List<Object?> get props => [
    id,
    seasonNumber,
    title,
    posterPath,
    overview,
    airDate,
    episodeCount,
    episodes,
  ];
}
