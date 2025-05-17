import 'package:flutter/material.dart';
import '../../../../core/widgets/media_card.dart';
import '../../services/watchlist_service.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';

class MediaSectionList extends StatefulWidget {
  final String title;
  final List<dynamic> mediaList;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final void Function(dynamic media)? onMediaTap;
  final String? watchlistId;

  const MediaSectionList({
    super.key,
    required this.title,
    required this.mediaList,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.onMediaTap,
    this.watchlistId,
  });

  @override
  State<MediaSectionList> createState() => _MediaSectionListState();
}

class _MediaSectionListState extends State<MediaSectionList> {
  late List<dynamic> _localMediaList;

  @override
  void initState() {
    super.initState();
    _localMediaList = List<dynamic>.from(widget.mediaList);
  }

  @override
  void didUpdateWidget(covariant MediaSectionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaList != widget.mediaList) {
      _localMediaList = List<dynamic>.from(widget.mediaList);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('\n============ MEDIA SECTION LIST ============');
    debugPrint(
        'Building MediaSectionList with \\${_localMediaList.length} items');

    if (widget.watchlistId != null) {
      debugPrint('Rendering for watchlist ID: \\${widget.watchlistId}');
      debugPrint('Media items to render:');
      for (var media in _localMediaList) {
        if (media is Movie) {
          debugPrint(
              '- ID: \\${media.id}, Type: movie, Title: \\${media.title}');
        } else if (media is TvShow) {
          debugPrint('- ID: \\${media.id}, Type: tv, Title: \\${media.title}');
        } else {
          debugPrint('- Unknown media type: \\${media.runtimeType}');
        }
      }
    }

    if (_localMediaList.isEmpty && widget.isLoadingMore) {
      debugPrint('Showing loading indicator (empty list + loading)');
      return Container(
        height: 286,
        margin: const EdgeInsets.only(bottom: 8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_localMediaList.isEmpty) {
      debugPrint('No items to display, returning empty widget');
      return const SizedBox.shrink();
    }

    debugPrint('Rendering media list with \\${_localMediaList.length} items');

    return Container(
      height: 286,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Positioned(
            top: 42,
            left: -7,
            right: 0,
            bottom: 0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  _localMediaList.length + (widget.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _localMediaList.length) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                }
                // Make a local copy of the list for this build
                final currentList = List<dynamic>.from(_localMediaList);
                final item = currentList[index];
                dynamic media;
                dynamic itemId;
                if (item is Map &&
                    item.containsKey('media') &&
                    item.containsKey('itemId')) {
                  media = item['media'];
                  itemId = item['itemId'];
                } else {
                  media = item;
                  if (media is Movie) {
                    itemId = 'movie_${media.id}';
                  } else if (media is TvShow) {
                    itemId = 'tv_${media.id}';
                  } else {
                    itemId = 'unknown_${media.hashCode}';
                  }
                }

                if (widget.watchlistId != null) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 150,
                    child: Dismissible(
                      key: ValueKey('watchlist_item_$itemId'),
                      direction: DismissDirection.vertical,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 8),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        // Remove from local list immediately
                        setState(() {
                          _localMediaList.removeAt(index);
                        });
                        try {
                          await context
                              .read<WatchlistService>()
                              .removeFromWatchlist(
                                widget.watchlistId!,
                                itemId,
                              );
                        } catch (e) {
                          // If DB removal fails, restore the item
                          setState(() {
                            _localMediaList.insert(index, item);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to remove from watchlist: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: MediaCard(
                        media: media,
                        onTap: () => widget.onMediaTap?.call(media),
                      ),
                    ),
                  );
                }

                return MediaCard(
                  media: media,
                  onTap: () => widget.onMediaTap?.call(media),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: widget.onLoadMore,
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
