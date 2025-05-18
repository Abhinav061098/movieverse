import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieverse/core/mixins/analytics_mixin.dart';
import 'package:movieverse/features/movies/models/genre.dart';
import 'package:movieverse/features/movies/models/media_item.dart';
import 'package:movieverse/features/movies/views/widgets/movie_discussion_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/movie_details.dart';
import '../../models/credits.dart';
import '../../services/movie_service.dart';
import '../../services/favorites_service.dart';
import '../widgets/add_to_watchlist_dialog.dart';
import '../widgets/smart_recommendations_widget.dart';
import '../../models/cast.dart';
import 'cast_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen>
    with AnalyticsMixin {
  late Future<MovieDetails> _movieDetailsFuture;
  late Future<String?> _certificationFuture;
  late Future<Map<String, dynamic>> _watchProvidersFuture;
  late MovieService _movieService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _movieService = Provider.of<MovieService>(context, listen: false);
    _movieDetailsFuture = _movieService.fetchMovieDetails(widget.movieId);
    _certificationFuture = _movieService.getMovieCertification(widget.movieId);
    _watchProvidersFuture = _movieService.getWatchProviders(widget.movieId);
  }

  Future<void> _launchTrailer(MovieDetails movie) async {
    if (movie.trailers.isEmpty) return;

    logEvent('watch_trailer', {
      'movie_id': widget.movieId,
      'movie_title': movie.title,
    });

    final trailer = movie.trailers.first;
    final url = 'https://www.youtube.com/watch?v=${trailer.videoId}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchUrl(String url) async {
    logEvent('open_watch_provider', {
      'movie_id': widget.movieId,
      'url': url,
    });

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildFavoriteButton() {
    final favoritesService = context.read<FavoritesService>();
    return StreamBuilder<List<dynamic>>(
      stream: favoritesService.favoritesStream,
      initialData: const [],
      builder: (context, snapshot) {
        final isFavorite = favoritesService.isMovieFavorite(widget.movieId);
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () async {
            try {
              final movieDetails = await _movieDetailsFuture;
              final success = await favoritesService.toggleMovieFavorite(
                widget.movieId,
                details: movieDetails,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Added to favorites'
                        : 'Removed from favorites'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildFavoriteAndWatchlistButtons(MovieDetails movie) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'favorite_button_movie_${widget.movieId}',
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: _buildFavoriteButton(),
          ),
        ),
        const SizedBox(height: 8),
        Hero(
          tag: 'watchlist_button_movie_${widget.movieId}',
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to add to watchlist'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                logEvent('add_to_watchlist_dialog', {
                  'movie_id': widget.movieId,
                  'movie_title': movie.title,
                });

                showDialog(
                  context: context,
                  builder: (context) => AddToWatchlistDialog(
                    mediaItem: MediaItem.fromMovieDetails(movie),
                  ),
                );
              },
              tooltip: 'Add to Watchlist',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<MovieDetails>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movie = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // Poster and Basic Info
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.6,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: movie.fullPosterPath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.black,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black,
                          child: const Icon(Icons.error),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: movie.voteAverage >= 7
                                        ? Colors.yellow
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFavoriteAndWatchlistButtons(movie),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Movie Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle Info (Genre, Runtime, Rating)
                      FutureBuilder<String?>(
                        future: _certificationFuture,
                        builder: (context, certSnapshot) {
                          return Row(
                            children: [
                              Text(
                                movie.genres
                                    .map((g) => (g as Genre?)?.name)
                                    .join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              const Text('•'),
                              const SizedBox(width: 8),
                              Text(movie.formattedRuntime),
                              if (certSnapshot.hasData &&
                                  certSnapshot.data != null) ...[
                                const SizedBox(width: 8),
                                const Text('•'),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    certSnapshot.data!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Overview
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(movie.overview),
                      const SizedBox(height: 16),

                      // Watch Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (movie.trailers.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _launchTrailer(movie),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Watch Trailer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _watchProvidersFuture,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final providers = snapshot.data!;
                              String? watchLink = providers['link']?.toString();

                              if (watchLink == null) {
                                return const SizedBox.shrink();
                              }

                              return ElevatedButton.icon(
                                onPressed: () => _launchUrl(watchLink),
                                icon: const Icon(Icons.tv),
                                label: const Text('Watch'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Credits Section
                      Text(
                        'Credits',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildCreditsSection(movie.credits.crew),
                      const SizedBox(height: 24),

                      // Cast Section
                      Text(
                        'Cast',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movie.credits.cast.length,
                          itemBuilder: (context, index) {
                            final castMember = movie.credits.cast[index];
                            return _buildCastCard(castMember);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Smart Recommendations
                      const SmartRecommendationsWidget(isMovie: true),
                      SizedBox(
                        height: 16,
                      ),
                      MovieDiscussionWidget(
                          mediaItem: MediaItem.fromMovieDetails(movie)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCreditsSection(List<CrewMember> crew) {
    final director = crew.firstWhere(
      (member) => member.job == 'Director',
      orElse: () => crew.first,
    );

    final writers =
        crew.where((member) => member.department == 'Writing').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreditRow('Director', director.name),
        if (writers.isNotEmpty)
          _buildCreditRow('Screenplay', writers.map((w) => w.name).join(', ')),
      ],
    );
  }

  Widget _buildCreditRow(String role, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastCard(CastMember castMember) {
    return GestureDetector(
      onTap: () async {
        // Update navigation to CastScreen to use castId, name, and profilePath only
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CastScreen(
              castId: castMember.id,
              name: castMember.name,
              profilePath: castMember.profilePath,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: castMember.fullProfilePath,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.person, size: 40),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.person, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              castMember.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              castMember.character,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
