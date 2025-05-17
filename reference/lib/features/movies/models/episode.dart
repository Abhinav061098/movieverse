import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';

part 'episode.g.dart';

@JsonSerializable()
class Episode extends Equatable {
  @JsonKey(name: 'id', defaultValue: 0)
  final int id;
  @JsonKey(name: 'episode_number', defaultValue: 0)
  final int episodeNumber;
  @JsonKey(name: 'name', defaultValue: '')
  final String name;
  @JsonKey(name: 'overview', defaultValue: '')
  final String overview;
  @JsonKey(name: 'still_path')
  final String? stillPath;
  @JsonKey(name: 'air_date')
  final String? airDate;
  @JsonKey(name: 'vote_average', defaultValue: 0.0)
  final double voteAverage;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.overview,
    this.stillPath,
    this.airDate,
    required this.voteAverage,
  });

  String get fullStillPath =>
      stillPath != null ? ApiConstants.imageUrlW500 + stillPath! : '';

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$EpisodeToJson(this);

  @override
  List<Object?> get props => [
    id,
    episodeNumber,
    name,
    overview,
    stillPath,
    airDate,
    voteAverage,
  ];
}
