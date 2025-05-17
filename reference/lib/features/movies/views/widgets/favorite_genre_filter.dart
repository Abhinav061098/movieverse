import 'package:flutter/material.dart';
import '../../models/genre.dart';

class FavoriteGenreFilter extends StatelessWidget {
  final List<Genre> genres;
  final int? selectedGenreId;
  final Function(int?) onGenreSelected;
  final Map<int, int> genreCounts;

  const FavoriteGenreFilter({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onGenreSelected,
    required this.genreCounts,
  });

  // Get icon for genre based on name
  IconData _getGenreIcon(String genreName) {
    switch (genreName.toLowerCase()) {
      case 'action':
        return Icons.local_fire_department;
      case 'adventure':
        return Icons.explore;
      case 'animation':
        return Icons.animation;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'crime':
        return Icons.gavel;
      case 'documentary':
        return Icons.camera_alt;
      case 'drama':
        return Icons.theater_comedy;
      case 'family':
        return Icons.family_restroom;
      case 'fantasy':
        return Icons.auto_fix_high;
      case 'history':
        return Icons.history;
      case 'horror':
        return Icons.coronavirus;
      case 'music':
        return Icons.music_note;
      case 'mystery':
        return Icons.search;
      case 'romance':
        return Icons.favorite;
      case 'science fiction':
        return Icons.rocket_launch;
      case 'tv movie':
        return Icons.tv;
      case 'thriller':
        return Icons.psychology;
      case 'war':
        return Icons.security;
      case 'western':
        return Icons.landscape;
      default:
        return Icons.movie;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: 8.0 + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genres',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  height: 32, // Making it more compact
                  decoration: BoxDecoration(
                    color: selectedGenreId == null
                        ? Colors.black
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(16), // More rounded corners
                    border: Border.all(
                      color: selectedGenreId == null
                          ? Colors.white
                          : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => onGenreSelected(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Show All',
                      style: TextStyle(
                        color: selectedGenreId == null
                            ? Colors.white
                            : Colors.grey[400],
                        fontSize: 13, // Slightly smaller text
                        fontWeight: selectedGenreId == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                final isSelected = selectedGenreId == genre.id;
                final count = genreCounts[genre.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onGenreSelected(genre.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 85,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.grey[700]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getGenreIcon(genre.name),
                              color:
                                  isSelected ? Colors.black : Colors.grey[400],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              genre.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[300],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
