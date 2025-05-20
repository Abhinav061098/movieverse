import 'movie.dart';

class MoodMovieData {
  final Map<String, List<String>> moodGenres;
  final Map<String, int> genreCounts;
  final Map<String, String> timeBasedPreferences;
  final List<Movie> movies;

  MoodMovieData({
    required this.moodGenres,
    required this.genreCounts,
    required this.timeBasedPreferences,
    required this.movies,
  });

  factory MoodMovieData.fromJson(Map<String, dynamic> json) {
    return MoodMovieData(
      moodGenres: Map<String, List<String>>.from(
        json['moodGenres'].map((key, value) => MapEntry(
              key,
              List<String>.from(value),
            )),
      ),
      genreCounts: Map<String, int>.from(json['genreCounts']),
      timeBasedPreferences:
          Map<String, String>.from(json['timeBasedPreferences']),
      movies: List<Movie>.from(json['movies'].map((e) => Movie.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moodGenres': moodGenres,
      'genreCounts': genreCounts,
      'timeBasedPreferences': timeBasedPreferences,
      'movies': movies.map((e) => e.toJson()).toList(),
    };
  }
}
