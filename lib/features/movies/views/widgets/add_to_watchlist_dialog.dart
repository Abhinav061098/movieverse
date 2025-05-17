import 'package:flutter/material.dart';
import 'package:movieverse/features/movies/models/watchlist.dart';
import 'package:provider/provider.dart';
import '../../models/media_item.dart';
import '../../services/watchlist_service.dart';

class AddToWatchlistDialog extends StatelessWidget {
  final MediaItem mediaItem;

  const AddToWatchlistDialog({
    super.key,
    required this.mediaItem,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer<WatchlistService>(
        builder: (context, watchlistService, child) {
          return StreamBuilder<List<Watchlist>>(
            stream: watchlistService.watchlistsStream,
            initialData: watchlistService.watchlists,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('AddToWatchlistDialog Error: ${snapshot.error}');
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('Failed to load watchlists'),
                  ),
                );
              }

              final watchlists = snapshot.data ?? [];
              debugPrint(
                  'AddToWatchlistDialog: Received ${watchlists.length} watchlists');

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add to Watchlist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (watchlists.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No watchlists yet. Create one first!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: watchlists.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final watchlist = watchlists[index];
                                  return ListTile(
                                    title: Text(watchlist.name),
                                    subtitle: Text(
                                      '${watchlist.items.length} items',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    onTap: () async {
                                      await watchlistService.addToWatchlist(
                                        watchlist.id,
                                        mediaItem,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Added to ${watchlist.name}'),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),

                            // Create New Watchlist Button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showCreateWatchlistDialog(context),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: const Text('Create New Watchlist'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateWatchlistDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Watchlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter watchlist name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter watchlist description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final watchlist = await context
                            .read<WatchlistService>()
                            .createWatchlist(
                              nameController.text,
                              descriptionController.text,
                            );
                        if (context.mounted) {
                          Navigator.pop(context); // Close create dialog
                          await context
                              .read<WatchlistService>()
                              .addToWatchlist(watchlist.id, mediaItem);
                          if (context.mounted) {
                            Navigator.pop(
                                context); // Close add to watchlist dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${watchlist.name}'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Create & Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
