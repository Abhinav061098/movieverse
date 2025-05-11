import 'package:flutter/material.dart';
import '../../models/genre.dart';

class GenreChips extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedGenreId;
  final Function(int?) onGenreSelected;

  const GenreChips({
    Key? key,
    required this.genres,
    required this.selectedGenreId,
    required this.onGenreSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedGenreId == null,
              onSelected: (_) => onGenreSelected(null),
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.transparent,
              labelStyle: TextStyle(
                color: selectedGenreId == null ? Colors.white : Colors.white,
              ),
            ),
          ),
          ...genres.map((genre) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(genre.name),
                  selected: selectedGenreId == genre.id,
                  onSelected: (_) => onGenreSelected(genre.id),
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.transparent,
                  labelStyle: TextStyle(
                    color: selectedGenreId == genre.id
                        ? Colors.white
                        : Colors.white,
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
