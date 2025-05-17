// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_trailer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovieTrailer _$MovieTrailerFromJson(Map<String, dynamic> json) => MovieTrailer(
      id: json['id'] as String,
      videoId: json['key'] as String,
      name: json['name'] as String,
      site: json['site'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
      official: json['official'] as bool,
      publishedAt: json['published_at'] as String,
    );

Map<String, dynamic> _$MovieTrailerToJson(MovieTrailer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.videoId,
      'name': instance.name,
      'site': instance.site,
      'size': instance.size,
      'type': instance.type,
      'official': instance.official,
      'published_at': instance.publishedAt,
    };
