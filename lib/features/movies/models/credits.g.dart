// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Credits _$CreditsFromJson(Map<String, dynamic> json) => Credits(
      cast: (json['cast'] as List<dynamic>)
          .map((e) => CastMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      crew: (json['crew'] as List<dynamic>)
          .map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreditsToJson(Credits instance) => <String, dynamic>{
      'cast': instance.cast,
      'crew': instance.crew,
    };

CastMember _$CastMemberFromJson(Map<String, dynamic> json) => CastMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      character: json['character'] as String,
      profilePath: json['profile_path'] as String?,
    );

Map<String, dynamic> _$CastMemberToJson(CastMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'profile_path': instance.profilePath,
    };

CrewMember _$CrewMemberFromJson(Map<String, dynamic> json) => CrewMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      department: json['department'] as String,
      job: json['job'] as String,
      profilePath: json['profile_path'] as String?,
    );

Map<String, dynamic> _$CrewMemberToJson(CrewMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'department': instance.department,
      'job': instance.job,
      'profile_path': instance.profilePath,
    };
