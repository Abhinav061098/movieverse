import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/trending_service.dart';
import '../../../../core/api/api_client.dart';
import 'shimmer_widgets.dart';
import '../screens/movie_details_screen.dart';
import '../screens/tv_show_details_screen.dart';

class TrendingWidget extends StatefulWidget {
  final String mediaType;

  const TrendingWidget({
    super.key,
    required this.mediaType,
  });

  @override
  State<TrendingWidget> createState() => _TrendingWidgetState();
}

class _TrendingWidgetState extends State<TrendingWidget>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _trendingFuture;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final trendingService = TrendingService(ApiClient());
    _trendingFuture = trendingService.getTrending(
      mediaType: widget.mediaType,
      timeWindow: 'day',
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToDetails(BuildContext context, dynamic item) {
    final id = item['id'];
    if (id == null) return;

    if (widget.mediaType == 'movie') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MovieDetailsScreen(movieId: id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TvShowDetailsScreen(tvShowId: id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              FadeTransition(
                opacity: _animation,
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Trending ${widget.mediaType == 'movie' ? 'Movies' : 'TV Shows'}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<dynamic>>(
          future: _trendingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerTrendingSection();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final trending = snapshot.data!;
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                itemBuilder: (context, index) {
                  final item = trending[index];
                  final posterPath = item['poster_path'];
                  return GestureDetector(
                    onTap: () => _navigateToDetails(context, item),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                if (posterPath != null)
                                  CachedNetworkImage(
                                    imageUrl:
                                        'https://image.tmdb.org/t/p/w500$posterPath',
                                    height: 200,
                                    width: 140,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const ShimmerTrendingCard(),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      height: 200,
                                      width: 140,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.movie,
                                          color: Colors.white54, size: 40),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 200,
                                    width: 140,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.movie,
                                        color: Colors.white54, size: 40),
                                  ),
                                // Gradient overlay for better text visibility
                                Positioned.fill(
                                  child: Container(
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
                                ),
                              ],
                            ),
                          ),
                          // Ranking badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
