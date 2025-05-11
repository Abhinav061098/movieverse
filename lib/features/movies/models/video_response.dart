import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'movie_trailer.dart';

part 'video_response.g.dart';

@JsonSerializable()
class VideoResponse extends Equatable {
  final List<MovieTrailer> results;

  const VideoResponse({required this.results});

  factory VideoResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoResponseToJson(this);

  @override
  List<Object?> get props => [results];
}
