// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'director.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Director _$DirectorFromJson(Map<String, dynamic> json) => Director(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      profilePath: json['profile_path'] as String?,
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      placeOfBirth: json['placeOfBirth'] as String?,
      knownForDepartment: json['knownForDepartment'] as String?,
      movieCredits: (json['movieCredits'] as List<dynamic>?)
          ?.map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList(),
      tvCredits: (json['tvCredits'] as List<dynamic>?)
          ?.map((e) => TvShow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DirectorToJson(Director instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profile_path': instance.profilePath,
      'biography': instance.biography,
      'birthday': instance.birthday,
      'placeOfBirth': instance.placeOfBirth,
      'knownForDepartment': instance.knownForDepartment,
      'movieCredits': instance.movieCredits,
      'tvCredits': instance.tvCredits,
    };
