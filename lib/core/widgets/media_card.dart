import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/movies/models/movie.dart';
import '../../features/movies/models/tv_show.dart';

class MediaCard extends StatelessWidget {
  final dynamic media; // Can be either Movie or TvShow
  final VoidCallback onTap;

  const MediaCard({super.key, required this.media, required this.onTap})
      : assert(media is Movie || media is TvShow);

  @override
  Widget build(BuildContext context) {
    final String posterPath;
    final double rating;

    if (media is Movie) {
      posterPath = (media as Movie).fullPosterPath;
      rating = (media as Movie).voteAverage;
    } else {
      posterPath = (media as TvShow).fullPosterPath;
      rating = (media as TvShow).voteAverage;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            // Poster Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: CachedNetworkImage(
                  imageUrl: posterPath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.error, color: Colors.white54),
                  ),
                ),
              ),
            ),
            // Rating Badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: rating >= 7
                          ? Colors.amber
                          : rating >= 5
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
