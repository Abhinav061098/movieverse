// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tv_show_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TvShowDetails _$TvShowDetailsFromJson(Map<String, dynamic> json) =>
    TvShowDetails(
      id: (json['id'] as num).toInt(),
      title: json['name'] as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: json['overview'] as String,
      firstAirDate: json['first_air_date'] as String,
      voteAverage: (json['vote_average'] as num).toDouble(),
      numberOfSeasons: (json['number_of_seasons'] as num).toInt(),
      genres: (json['genres'] as List<dynamic>)
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      credits: Credits.fromJson(json['credits'] as Map<String, dynamic>),
      videos: VideoResponse.fromJson(json['videos'] as Map<String, dynamic>),
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TvShowDetailsToJson(TvShowDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.title,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'overview': instance.overview,
      'first_air_date': instance.firstAirDate,
      'vote_average': instance.voteAverage,
      'number_of_seasons': instance.numberOfSeasons,
      'genres': instance.genres,
      'credits': instance.credits,
      'videos': instance.videos,
      'seasons': instance.seasons,
    };
