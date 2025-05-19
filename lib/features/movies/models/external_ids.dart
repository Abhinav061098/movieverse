import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'external_ids.g.dart';

@JsonSerializable()
class ExternalIds extends Equatable {
  @JsonKey(name: 'imdb_id')
  final String? imdbId;
  @JsonKey(name: 'facebook_id')
  final String? facebookId;
  @JsonKey(name: 'instagram_id')
  final String? instagramId;
  @JsonKey(name: 'twitter_id')
  final String? twitterId;

  const ExternalIds({
    this.imdbId,
    this.facebookId,
    this.instagramId,
    this.twitterId,
  });

  factory ExternalIds.fromJson(Map<String, dynamic> json) =>
      _$ExternalIdsFromJson(json);

  Map<String, dynamic> toJson() => _$ExternalIdsToJson(this);

  @override
  List<Object?> get props => [
        imdbId,
        facebookId,
        instagramId,
        twitterId,
      ];
}
