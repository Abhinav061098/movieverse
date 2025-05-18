import 'package:json_annotation/json_annotation.dart';

import 'movie.dart';
import 'tv_show.dart';

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
  final List<Movie>? movieCredits;
  final List<TvShow>? tvCredits;

  Director({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.knownForDepartment,
    this.movieCredits,
    this.tvCredits,
  });

  factory Director.fromJson(Map<String, dynamic> json) {
    // Parse movie_credits and tv_credits if present
    List<Movie>? movieCredits;
    List<TvShow>? tvCredits;
    if (json['movie_credits'] != null &&
        json['movie_credits']['crew'] != null) {
      movieCredits = (json['movie_credits']['crew'] as List)
          .where((c) => (c['job'] ?? '').toString().toLowerCase() == 'director')
          .map((c) => Movie.fromJson(c))
          .toList();
    }
    if (json['tv_credits'] != null && json['tv_credits']['crew'] != null) {
      tvCredits = (json['tv_credits']['crew'] as List)
          .where((c) => (c['job'] ?? '').toString().toLowerCase() == 'director')
          .map((c) => TvShow.fromJson(c))
          .toList();
    }
    return Director(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      biography: json['biography'],
      birthday: json['birthday'],
      placeOfBirth: json['placeOfBirth'] ?? json['place_of_birth'],
      knownForDepartment:
          json['knownForDepartment'] ?? json['known_for_department'],
      movieCredits: movieCredits,
      tvCredits: tvCredits,
    );
  }
  Map<String, dynamic> toJson() => _$DirectorToJson(this);

  String get fullProfilePath =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w500$profilePath' : '';
}
