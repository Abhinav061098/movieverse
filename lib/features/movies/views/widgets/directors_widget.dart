import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/director.dart';
import '../screens/director_screen.dart';
import '../../services/director_service.dart';

class DirectorsWidget extends StatelessWidget {
  final List<Director> directors;
  final String title;
  final VoidCallback? onSeeAllPressed;
  final bool isLoading;

  const DirectorsWidget({
    super.key,
    required this.directors,
    this.title = 'Directors',
    this.onSeeAllPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (onSeeAllPressed != null)
                  TextButton(
                    onPressed: onSeeAllPressed,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('See All'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!isLoading && directors.isEmpty)
            const Center(child: Text('No directors found'))
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: directors.length,
                itemBuilder: (context, index) {
                  final director = directors[index];
                  return DirectorCard(
                    director: director,
                    onTap: () async {
                      final directorService = context.read<DirectorService>();
                      try {
                        final fullDirector = await directorService
                            .getDirectorDetails(director.id);
                        final movies = fullDirector.movieCredits ?? [];
                        final tvShows = fullDirector.tvCredits ?? [];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectorScreen(
                              director: fullDirector,
                              movies: movies,
                              tvShows: tvShows,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Failed to load director details.')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class DirectorCard extends StatelessWidget {
  final Director director;
  final VoidCallback? onTap;

  const DirectorCard({
    super.key,
    required this.director,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Director Image
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: director.profilePath != null
                    ? CachedNetworkImage(
                        imageUrl: director.fullProfilePath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.person, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.person, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Director Name
            Text(
              director.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
