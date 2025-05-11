// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
      id: (json['id'] as num?)?.toInt() ?? 0,
      seasonNumber: (json['season_number'] as num?)?.toInt() ?? 0,
      title: json['name'] as String,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String? ?? '',
      airDate: json['air_date'] as String?,
      episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
      'id': instance.id,
      'season_number': instance.seasonNumber,
      'name': instance.title,
      'poster_path': instance.posterPath,
      'overview': instance.overview,
      'air_date': instance.airDate,
      'episode_count': instance.episodeCount,
      if (instance.episodes case final value?) 'episodes': value,
    };
