import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_constants.dart';

part 'credits.g.dart';

@JsonSerializable()
class Credits extends Equatable {
  final List<CastMember> cast;
  final List<CrewMember> crew;

  const Credits({required this.cast, required this.crew});

  factory Credits.empty() => const Credits(cast: [], crew: []);

  factory Credits.fromJson(Map<String, dynamic> json) =>
      _$CreditsFromJson(json);
  Map<String, dynamic> toJson() => _$CreditsToJson(this);

  @override
  List<Object?> get props => [cast, crew];
}

@JsonSerializable()
class CastMember extends Equatable {
  final int id;
  final String name;
  final String character;
  @JsonKey(name: 'profile_path')
  final String? profilePath;

  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  String get fullProfilePath =>
      profilePath != null ? ApiConstants.imageUrlW500 + profilePath! : '';

  factory CastMember.fromJson(Map<String, dynamic> json) =>
      _$CastMemberFromJson(json);
  Map<String, dynamic> toJson() => _$CastMemberToJson(this);

  @override
  List<Object?> get props => [id, name, character, profilePath];
}

@JsonSerializable()
class CrewMember extends Equatable {
  final int id;
  final String name;
  final String department;
  final String job;
  @JsonKey(name: 'profile_path')
  final String? profilePath;

  const CrewMember({
    required this.id,
    required this.name,
    required this.department,
    required this.job,
    this.profilePath,
  });

  String get fullProfilePath =>
      profilePath != null ? ApiConstants.imageUrlW500 + profilePath! : '';

  factory CrewMember.fromJson(Map<String, dynamic> json) =>
      _$CrewMemberFromJson(json);
  Map<String, dynamic> toJson() => _$CrewMemberToJson(this);

  @override
  List<Object?> get props => [id, name, department, job, profilePath];
}
