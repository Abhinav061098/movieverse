import 'package:json_annotation/json_annotation.dart';

part 'director.g.dart';

@JsonSerializable()
class Director {
  final int id;
  final String name;
  @JsonKey(name: 'profile_path')
  final String? profilePath;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? knownForDepartment;

  Director({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.knownForDepartment,
  });

  factory Director.fromJson(Map<String, dynamic> json) =>
      _$DirectorFromJson(json);
  Map<String, dynamic> toJson() => _$DirectorToJson(this);

  String get fullProfilePath =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w500$profilePath' : '';
}
