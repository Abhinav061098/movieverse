import 'package:flutter/material.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:movieverse/core/widgets/media_card.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../viewmodels/media_list_viewmodel.dart';

class TrendingContent extends StatefulWidget {
  final MediaType mediaType;

  const TrendingContent({
    super.key,
    required this.mediaType,
  });

  @override
  State<TrendingContent> createState() => _TrendingContentState();
}

class _TrendingContentState extends State<TrendingContent>
    with AutomaticKeepAliveClientMixin {
  List<MediaItem> _trendingItems = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<MediaListViewModel>();
    // Only reload if there's an error or no items
    if (viewModel.state == MediaListState.error || _trendingItems.isEmpty) {
      _loadTrendingContent();
    }
  }

  Future<void> _loadTrendingContent() async {
    if (!mounted) return;

    final viewModel = context.read<MediaListViewModel>();
    try {
      setState(() {
        _isLoading = true;
      });

      List<dynamic> trending;
      if (widget.mediaType == MediaType.movie) {
        trending = await viewModel.movieService.getTrendingMovies();
        _trendingItems = trending.map((m) => MediaItem.fromMovie(m)).toList();
      } else {
        trending = await viewModel.tvService.getTrendingTvShows();
        _trendingItems = trending.map((s) => MediaItem.fromTvShow(s)).toList();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        context.read<FirebaseService>().logEvent('trending_content_shown', {
          'content_count': _trendingItems.length,
          'media_type': widget.mediaType == MediaType.movie ? 'movie' : 'tv',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error loading trending content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 250,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_trendingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trending Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.red[300],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _trendingItems.length,
              itemBuilder: (context, index) {
                final item = _trendingItems[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: MediaCard(
                            media: item,
                            onTap: () {
                              context.read<FirebaseService>().logEvent(
                                'trending_content_selected',
                                {
                                  'content_id': item.item.id.toString(),
                                  'content_type': item.item.mediaType,
                                  'position': index,
                                  'timestamp': DateTime.now().toIso8601String(),
                                },
                              );
                              context
                                  .read<MediaListViewModel>()
                                  .navigateToDetails(
                                    context,
                                    item.item,
                                  );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.trending_up,
                                size: 12,
                                color: Colors.red[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
