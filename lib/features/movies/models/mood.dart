import 'package:flutter/material.dart';

class Mood {
  final String name;
  final IconData icon;
  final List<int> movieGenreIds;
  final List<int> tvShowGenreIds;
  final String description;
  final Color color;

  const Mood({
    required this.name,
    required this.icon,
    required this.movieGenreIds,
    required this.tvShowGenreIds,
    required this.description,
    required this.color,
  });

  static const List<Mood> moods = [
    Mood(
      name: 'Happy',
      icon: Icons.sentiment_very_satisfied,
      movieGenreIds: [35, 10751], // Comedy, Family
      tvShowGenreIds: [35, 10751], // Comedy, Family
      description: 'Light-hearted and feel-good content',
      color: Colors.amber,
    ),
    Mood(
      name: 'Excited',
      icon: Icons.local_fire_department,
      movieGenreIds: [28, 12], // Action, Adventure
      tvShowGenreIds: [10759], // Action & Adventure
      description: 'High-energy and thrilling content',
      color: Colors.red,
    ),
    Mood(
      name: 'Relaxed',
      icon: Icons.spa,
      movieGenreIds: [18, 14], // Drama, Fantasy
      tvShowGenreIds: [18, 14], // Drama, Fantasy
      description: 'Calm and contemplative content',
      color: Colors.green,
    ),
    Mood(
      name: 'Romantic',
      icon: Icons.favorite,
      movieGenreIds: [10749], // Romance
      tvShowGenreIds: [10749], // Romance
      description: 'Love stories and romantic content',
      color: Colors.pink,
    ),
    Mood(
      name: 'Thoughtful',
      icon: Icons.psychology,
      movieGenreIds: [18, 9648], // Drama, Mystery
      tvShowGenreIds: [18, 9648], // Drama, Mystery
      description: 'Intellectual and thought-provoking content',
      color: Colors.purple,
    ),
    Mood(
      name: 'Scared',
      icon: Icons.nightlight_round,
      movieGenreIds: [27, 53], // Horror, Thriller
      tvShowGenreIds: [27, 53], // Horror, Thriller
      description: 'Spine-chilling horror and thrillers',
      color: Colors.deepPurple,
    ),
  ];
}
