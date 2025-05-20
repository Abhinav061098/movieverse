// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cast _$CastFromJson(Map<String, dynamic> json) => Cast(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      profilePath: json['profile_path'] as String?,
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      movies: (json['movies'] as List<dynamic>?)
          ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList(),
      tvShows: (json['tvShows'] as List<dynamic>?)
          ?.map((e) => TvShow.fromJson(e as Map<String, dynamic>))
          .toList(),
      externalIds: json['external_ids'] == null
          ? null
          : ExternalIds.fromJson(json['external_ids'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CastToJson(Cast instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profile_path': instance.profilePath,
      'biography': instance.biography,
      'birthday': instance.birthday,
      'place_of_birth': instance.placeOfBirth,
      'known_for_department': instance.knownForDepartment,
      'movies': instance.movies,
      'tvShows': instance.tvShows,
      'external_ids': instance.externalIds,
    };

ExternalIds _$ExternalIdsFromJson(Map<String, dynamic> json) => ExternalIds(
      instagramId: json['instagram_id'] as String?,
      twitterId: json['twitter_id'] as String?,
      facebookId: json['facebook_id'] as String?,
      imdbId: json['imdb_id'] as String?,
    );

Map<String, dynamic> _$ExternalIdsToJson(ExternalIds instance) =>
    <String, dynamic>{
      'instagram_id': instance.instagramId,
      'twitter_id': instance.twitterId,
      'facebook_id': instance.facebookId,
      'imdb_id': instance.imdbId,
    };
