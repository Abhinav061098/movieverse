import 'package:flutter/material.dart';
import 'package:movieverse/features/movies/models/media_item.dart';
import '../../../../core/widgets/media_card.dart';
import '../../viewmodels/media_list_viewmodel.dart';
import '../../services/watchlist_service.dart';
import 'package:provider/provider.dart';

class MediaSectionList extends StatelessWidget {
  final String title;
  final List<dynamic> mediaList;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final String? watchlistId;

  const MediaSectionList({
    super.key,
    required this.title,
    required this.mediaList,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.watchlistId,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('\n============ MEDIA SECTION LIST ============');
    debugPrint('Building MediaSectionList with ${mediaList.length} items');
    if (watchlistId != null) {
      debugPrint('Rendering for watchlist ID: $watchlistId');
      debugPrint('Media items to render:');
      for (var media in mediaList) {
        final actualMedia = media is MediaItem ? media.item : media;
        debugPrint(
            '- ID: ${actualMedia.id}, Type: ${actualMedia.mediaType}, Title: ${actualMedia.title ?? actualMedia.name}');
      }
    }

    // Show loading indicator while initial data is loading
    if (mediaList.isEmpty && isLoadingMore) {
      debugPrint('Showing loading indicator (empty list + loading)');
      return Container(
        height: 286,
        margin: const EdgeInsets.only(bottom: 8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Skip rendering if there's no data and not loading
    if (mediaList.isEmpty) {
      debugPrint('No items to display, returning empty widget');
      return const SizedBox.shrink();
    }

    debugPrint('Rendering media list with ${mediaList.length} items');
    debugPrint(
        'MediaSectionList: First item type: ${mediaList.first.runtimeType}');

    return Container(
      height: 286,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Positioned(
            top: 42,
            left: 0,
            right: 0,
            bottom: 0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mediaList.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == mediaList.length) {
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

                final media = mediaList[index];
                final actualMedia = media is MediaItem ? media.item : media;

                if (watchlistId != null) {
                  final itemId = '${media.mediaType}_${media.id}';
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 150,
                    child: Dismissible(
                      key: ValueKey('watchlist_item_$itemId'),
                      direction: DismissDirection.vertical,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Remove from Watchlist'),
                              content: const Text(
                                  'Are you sure you want to remove this item from the watchlist?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Remove',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          final watchlistService =
                              context.read<WatchlistService>();
                          await watchlistService.removeFromWatchlist(
                            watchlistId!,
                            itemId,
                          );

                          // Show success message after successful removal
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item removed from watchlist'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          // Show error message if removal fails
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error removing item: $e'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: MediaCard(
                        media: actualMedia,
                        onTap: () {
                          context.read<MediaListViewModel>().navigateToDetails(
                                context,
                                actualMedia,
                              );
                        },
                      ),
                    ),
                  );
                }

                return MediaCard(
                  media: actualMedia,
                  onTap: () {
                    context.read<MediaListViewModel>().navigateToDetails(
                          context,
                          actualMedia,
                        );
                  },
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
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (onLoadMore != null)
                    TextButton(
                      onPressed: onLoadMore,
                      child: const Text('See All'),
                    ),
                ],
              ),
            ),
          ),
          if (isLoadingMore && mediaList.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
