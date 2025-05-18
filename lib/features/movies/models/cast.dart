import 'package:json_annotation/json_annotation.dart';
import 'movie.dart';
import 'tv_show.dart';

part 'cast.g.dart';

@JsonSerializable()
class Cast {
  final int id;
  final String name;
  @JsonKey(name: 'profile_path')
  final String? profilePath;
  final String? biography;
  final String? birthday;
  @JsonKey(name: 'place_of_birth')
  final String? placeOfBirth;
  final List<Movie>? movies;
  final List<TvShow>? tvShows;

  Cast({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.movies,
    this.tvShows,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    List<Movie>? movies;
    List<TvShow>? tvShows;
    if (json['movie_credits'] != null &&
        json['movie_credits']['cast'] != null) {
      movies = (json['movie_credits']['cast'] as List)
          .map((c) => Movie.fromJson(c))
          .toList();
    }
    if (json['tv_credits'] != null && json['tv_credits']['cast'] != null) {
      tvShows = (json['tv_credits']['cast'] as List)
          .map((c) => TvShow.fromJson(c))
          .toList();
    }
    return Cast(
      id: json['id'],
      name: json['name'],
      profilePath: json['profile_path'],
      biography: json['biography'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
      movies: movies,
      tvShows: tvShows,
    );
  }

  Map<String, dynamic> toJson() => _$CastToJson(this);

  String get fullProfilePath =>
      profilePath != null ? 'https://image.tmdb.org/t/p/w500$profilePath' : '';
}
