import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'movie_trailer.g.dart';

@JsonSerializable()
class MovieTrailer extends Equatable {
  final String id;
  @JsonKey(name: 'key')
  final String videoId;
  final String name;
  final String site;
  final int size;
  final String type;
  final bool official;
  @JsonKey(name: 'published_at')
  final String publishedAt;

  const MovieTrailer({
    required this.id,
    required this.videoId,
    required this.name,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.publishedAt,
  });

  factory MovieTrailer.fromJson(Map<String, dynamic> json) =>
      _$MovieTrailerFromJson(json);
  Map<String, dynamic> toJson() => _$MovieTrailerToJson(this);

  @override
  List<Object?> get props => [
        id,
        videoId,
        name,
        site,
        size,
        type,
        official,
        publishedAt,
      ];
}
