import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/api/api_client.dart';
import '../../models/movie_details.dart';
import '../../models/media_item.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../widgets/movie_discussion_widget.dart';

class MediaSocialScreen extends StatefulWidget {
  final dynamic media;
  final String? imdbId;
  final String? homepage;

  const MediaSocialScreen({
    super.key,
    required this.media,
    this.imdbId,
    this.homepage,
  });

  @override
  State<MediaSocialScreen> createState() => _MediaSocialScreenState();
}

class _MediaSocialScreenState extends State<MediaSocialScreen> {
  late Future<List<Review>> _reviewsFuture;
  final ReviewService _reviewService = ReviewService(ApiClient());
  int _currentPage = 1;
  List<Review> _allReviews = [];
  bool _isLoadingMore = false;
  bool _hasMoreReviews = true;
  bool _isReviewsExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadInitialReviews();
  }

  Future<void> _loadInitialReviews() async {
    _reviewsFuture = widget.media is MovieDetails
        ? _reviewService.getMovieReviews(widget.media.id)
        : _reviewService.getTvShowReviews(widget.media.id);

    final reviews = await _reviewsFuture;
    setState(() {
      _allReviews = reviews;
      _hasMoreReviews =
          reviews.length >= 20; // TMDB typically returns 20 items per page
    });
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreReviews) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newReviews = widget.media is MovieDetails
          ? await _reviewService.getMovieReviews(widget.media.id,
              page: nextPage)
          : await _reviewService.getTvShowReviews(widget.media.id,
              page: nextPage);

      setState(() {
        _allReviews.addAll(newReviews);
        _currentPage = nextPage;
        _hasMoreReviews = newReviews.length >= 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      debugPrint('Error loading more reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = widget.media is MovieDetails
        ? MediaItem.fromMovieDetails(widget.media)
        : MediaItem.fromTvShowDetails(widget.media);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            backgroundColor: Colors.black,
            title: const Text('Social & Discussion'),
            pinned: true,
          ),

          // Media Info Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.media.fullPosterPath,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, size: 40),
                      ),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.media.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.media.genres.map((g) => g.name).join(', '),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.media.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Social Media Icons
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Social Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.media.externalIds?.instagramId != null)
                        _buildSocialButton(
                          FontAwesomeIcons.instagram,
                          const Color(0xFFE1306C),
                          'https://instagram.com/${widget.media.externalIds!.instagramId}',
                        ),
                      if (widget.media.externalIds?.twitterId != null)
                        _buildSocialButton(
                          FontAwesomeIcons.twitter,
                          const Color(0xFF1DA1F2),
                          'https://twitter.com/${widget.media.externalIds!.twitterId}',
                        ),
                      if (widget.media.externalIds?.facebookId != null)
                        _buildSocialButton(
                          FontAwesomeIcons.facebook,
                          const Color(0xFF4267B2),
                          'https://facebook.com/${widget.media.externalIds!.facebookId}',
                        ),
                      if (widget.imdbId != null)
                        _buildSocialButton(
                          FontAwesomeIcons.imdb,
                          const Color(0xFFF5C518),
                          'https://www.imdb.com/title/${widget.imdbId}',
                        ),
                      _buildSocialButton(
                        Icons.image,
                        const Color(0xFF032541),
                        'https://www.themoviedb.org/${widget.media is MovieDetails ? 'movie' : 'tv'}/${widget.media.id}',
                        imagePath: 'assets/svg/tmdb.svg',
                      ),
                      _buildSocialButton(
                        Icons.image,
                        const Color(0xFFFA320A),
                        'https://www.rottentomatoes.com/search?search=${Uri.encodeComponent(widget.media.title)}',
                        imagePath: 'assets/icons/rotten-tomato.png',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Reviews Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isReviewsExpanded = !_isReviewsExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          _isReviewsExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  if (_isReviewsExpanded) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<List<Review>>(
                      future: _reviewsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error loading reviews: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        if (_allReviews.isEmpty) {
                          return const Text(
                            'No reviews available',
                            style: TextStyle(color: Colors.white70),
                          );
                        }

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allReviews.length,
                              itemBuilder: (context, index) {
                                final review = _allReviews[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey[700],
                                            child: review.authorDetails
                                                        .avatarPath !=
                                                    null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: CachedNetworkImage(
                                                      imageUrl: review
                                                          .authorDetails
                                                          .avatarPath!,
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          const Icon(
                                                              Icons.person),
                                                    ),
                                                  )
                                                : const Icon(Icons.person),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  review.author,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                if (review
                                                        .authorDetails.rating !=
                                                    null)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        review.authorDetails
                                                            .rating
                                                            .toString(),
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatDate(review.createdAt),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        review.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          height: 1.5,
                                        ),
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (_hasMoreReviews)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: _isLoadingMore
                                        ? null
                                        : _loadMoreReviews,
                                    child: _isLoadingMore
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Load More Reviews',
                                            style:
                                                TextStyle(color: Colors.purple),
                                          ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Discussion Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discussion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MovieDiscussionWidget(mediaItem: mediaItem),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSocialButton(IconData icon, Color color, String url,
      {String? imagePath}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: () async {
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
        },
        child: imagePath != null
            ? imagePath.endsWith('.svg')
                ? SvgPicture.asset(
                    imagePath,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Image.asset(
                    imagePath,
                    width: 24,
                    height: 24,
                    color: color,
                  )
            : Icon(icon, color: color, size: 24),
      ),
    );
  }
}
