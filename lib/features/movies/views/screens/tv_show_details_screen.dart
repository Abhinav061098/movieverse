import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movieverse/core/api/api_client.dart';
import 'package:movieverse/features/movies/models/media_item.dart';
import 'package:movieverse/features/movies/views/screens/media_social_screen.dart';
import 'package:movieverse/features/movies/views/widgets/movie_discussion_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/tv_show_details.dart';
import '../../models/season.dart';
import '../../models/credits.dart';
import '../../services/tv_service.dart';
import '../../services/favorites_service.dart';
import '../widgets/add_to_watchlist_dialog.dart';
import 'package:movieverse/core/mixins/analytics_mixin.dart';
import '../widgets/smart_recommendations_widget.dart';
import '../widgets/detail_shimmer_widgets.dart';
import '../widgets/watch_providers_dialog.dart';
import 'cast_screen.dart';

class TvShowDetailsScreen extends StatefulWidget {
  final int tvShowId;

  const TvShowDetailsScreen({super.key, required this.tvShowId});

  @override
  State<TvShowDetailsScreen> createState() => _TvShowDetailsScreenState();
}

class _TvShowDetailsScreenState extends State<TvShowDetailsScreen>
    with AnalyticsMixin {
  late Future<TvShowDetails> _tvShowDetailsFuture;
  late Future<Map<String, dynamic>> _watchProvidersFuture;
  Future<Season>? _selectedSeasonFuture;
  final TvService _tvService = TvService(ApiClient());
  int _selectedSeasonNumber = 1;

  @override
  void initState() {
    super.initState();
    _tvShowDetailsFuture = _tvService.fetchTvShowDetails(widget.tvShowId);
    _watchProvidersFuture = _tvService.getWatchProviders(widget.tvShowId);
    _loadSelectedSeason();
  }

  void _loadSelectedSeason() {
    _selectedSeasonFuture = _tvService.fetchSeasonDetails(
      widget.tvShowId,
      _selectedSeasonNumber,
    );

    logEvent('select_season', {
      'tv_show_id': widget.tvShowId,
      'season_number': _selectedSeasonNumber,
    });

    setState(() {});
  }

  Future<void> _launchTrailer(TvShowDetails show) async {
    if (show.trailers.isEmpty) return;

    logEvent('watch_trailer', {
      'content_type': 'tv_show',
      'tv_show_id': widget.tvShowId,
      'tv_show_title': show.title,
    });

    final trailer = show.trailers.first;
    final url = 'https://www.youtube.com/watch?v=${trailer.videoId}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        // Fallback to browser if app launch fails
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    logEvent('open_watch_provider', {
      'content_type': 'tv_show',
      'tv_show_id': widget.tvShowId,
      'url': url,
    });

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildCreditsSection(List<CrewMember> crew) {
    if (crew.isEmpty) {
      return const Text('No crew information available');
    }

    // Find director with fallbacks
    final director = crew.firstWhere(
      (member) =>
          member.job.toLowerCase() == 'director' ||
          member.job.toLowerCase() == 'series director',
      orElse: () => crew.firstWhere(
        (member) => member.department.toLowerCase() == 'directing',
        orElse: () => crew.firstWhere(
          (member) => member.department.toLowerCase() == 'production',
          orElse: () => crew.first,
        ),
      ),
    );

    // Find writers
    final writers = crew
        .where(
          (member) =>
              member.department.toLowerCase() == 'writing' ||
              member.job.toLowerCase().contains('writer'),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreditRow('Director/Creator', director.name),
        if (writers.isNotEmpty)
          _buildCreditRow('Writers', writers.map((w) => w.name).join(', ')),
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

  Widget _buildFavoriteButton() {
    final favoritesService = context.read<FavoritesService>();
    return StreamBuilder<List<dynamic>>(
      stream: favoritesService.favoritesStream,
      initialData: const [],
      builder: (context, snapshot) {
        final isFavorite = favoritesService.isTvShowFavorite(widget.tvShowId);
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () async {
            try {
              final tvShowDetails = await _tvShowDetailsFuture;
              final success = await favoritesService.toggleTvShowFavorite(
                widget.tvShowId,
                details: tvShowDetails,
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
                    content: Text('Error updating favorites: $e'),
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

  Widget _buildFavoriteAndWatchlistButtons(TvShowDetails show) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'favorite_button_tv_${widget.tvShowId}',
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: _buildFavoriteButton(),
          ),
        ),
        const SizedBox(height: 8),
        Hero(
          tag: 'watchlist_button_tv_${widget.tvShowId}',
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
                  'tv_show_id': widget.tvShowId,
                  'tv_show_title': show.title,
                });

                showDialog(
                  context: context,
                  builder: (context) => AddToWatchlistDialog(
                    mediaItem: MediaItem.fromTvShowDetails(show),
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
      body: FutureBuilder<TvShowDetails>(
        future: _tvShowDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.6,
                  pinned: true,
                  flexibleSpace: const ShimmerDetailHeader(),
                ),
                const SliverToBoxAdapter(
                  child: ShimmerDetailInfo(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerCreditsSection(),
                        const SizedBox(height: 24),
                        Container(
                          width: 100,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) =>
                                const ShimmerCastCard(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 150,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (context, index) =>
                                const ShimmerEpisodeCard(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SmartRecommendationsWidget(isMovie: false),
                        const SizedBox(height: 16),
                        const ShimmerCreditsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final show = snapshot.data!;

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
                        imageUrl: show.fullPosterPath,
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
                                    color: show.voteAverage >= 7
                                        ? Colors.yellow
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    show.voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildFavoriteAndWatchlistButtons(show),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        show.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Genre and First Air Date
                      Row(
                        children: [
                          Text(
                            show.genres.map((g) => g.name).join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          const Text('•'),
                          const SizedBox(width: 8),
                          Text(show.firstAirDate),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Overview
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(show.overview),
                      const SizedBox(height: 16),

                      // Watch Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (show.trailers.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _launchTrailer(show),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Trailer'),
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

                              return ElevatedButton.icon(
                                onPressed: () {
                                  WatchProvidersDialog.show(
                                    context,
                                    mediaId: widget.tvShowId,
                                    isMovie: false,
                                    title: show.title,
                                  );
                                },
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
                          const SizedBox(width: 12),
                          // Add the new Social & Discussion button here
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MediaSocialScreen(
                                    media: show,
                                    imdbId: show.externalIds?.imdbId,
                                    homepage: show.homepage,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.forum),
                            label: const Text('Reviews'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
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
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Credits Section
                      Text(
                        'Credits',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildCreditsSection(show.credits.crew),
                      const SizedBox(height: 24),

                      // Seasons Dropdown
                      Row(
                        children: [
                          Text(
                            'Seasons',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: _selectedSeasonNumber,
                            items: List.generate(
                              show.numberOfSeasons,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('Season ${index + 1}'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSeasonNumber = value;
                                  _loadSelectedSeason();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Episodes
                      FutureBuilder<Season>(
                        future: _selectedSeasonFuture,
                        builder: (context, seasonSnapshot) {
                          if (seasonSnapshot.hasError) {
                            return Text('Error: ${seasonSnapshot.error}');
                          }

                          if (!seasonSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final season = seasonSnapshot.data!;
                          if (season.episodes == null ||
                              season.episodes!.isEmpty) {
                            return const Text('No episodes available.');
                          }

                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: season.episodes!.length,
                              itemBuilder: (context, index) {
                                final episode = season.episodes![index];
                                return Container(
                                  width: 300,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: episode.fullStillPath,
                                          height: 200,
                                          width: 300,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[850],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[850],
                                            child: const Icon(
                                              Icons.error,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            episode.voteAverage.toStringAsFixed(
                                              1,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        right: 8,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Episode ${episode.episodeNumber}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              episode.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              episode.overview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cast',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: show.credits.cast.length,
                          itemBuilder: (context, index) {
                            final castMember = show.credits.cast[index];
                            return _buildCastCard(castMember);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 16),
                      const SmartRecommendationsWidget(isMovie: false),
                      SizedBox(
                        height: 16,
                      ),
                      MovieDiscussionWidget(
                          mediaItem: MediaItem.fromTvShowDetails(show)),
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
}
