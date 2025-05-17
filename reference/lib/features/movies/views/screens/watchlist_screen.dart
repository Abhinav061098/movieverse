import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/watchlist_service.dart';
import '../../models/watchlist.dart';
import '../widgets/media_section_list.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('\n============ WATCHLIST SCREEN BUILD ============');
    return Scaffold(
      body: Consumer<WatchlistService>(
        builder: (context, watchlistService, child) {
          debugPrint('WatchlistScreen: Consumer rebuilding');
          return StreamBuilder<List<Watchlist>>(
            stream: watchlistService.watchlistsStream,
            initialData: watchlistService.watchlists,
            builder: (context, snapshot) {
              debugPrint('\nSTREAM BUILDER STATE:');
              debugPrint('- Connection state: ${snapshot.connectionState}');
              debugPrint('- Has error: ${snapshot.hasError}');
              debugPrint('- Has data: ${snapshot.hasData}');

              if (snapshot.hasError) {
                debugPrint('Error: ${snapshot.error}');
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final watchlists = snapshot.data ?? [];
              debugPrint('\nWATCHLISTS DATA:');
              debugPrint('Total watchlists received: ${watchlists.length}');

              for (final watchlist in watchlists) {
                debugPrint(
                    '\nWatchlist "${watchlist.name}" (${watchlist.id}):');
                debugPrint('- Total items: ${watchlist.items.length}');
                if (watchlist.items.isNotEmpty) {
                  debugPrint('- Item IDs: ${watchlist.items.keys.join(", ")}');
                }
              }

              // Show empty state if no watchlists
              if (watchlists.isEmpty) {
                debugPrint('\nNo watchlists to display');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No watchlists yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showCreateWatchlistDialog(context),
                        child: const Text('Create Watchlist'),
                      ),
                    ],
                  ),
                );
              }

              debugPrint('\nRendering watchlists in UI...');
              // Show watchlist content
              return Stack(
                children: [
                  ListView.builder(
                    itemCount: watchlists.length,
                    itemBuilder: (context, index) {
                      final watchlist = watchlists[index];
                      debugPrint('Rendering watchlist: ${watchlist.name}');
                      return ExpansionTile(
                        title: Text(watchlist.name),
                        subtitle: Text(
                          '${watchlist.items.length} items • ${watchlist.description}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDeleteWatchlist(
                            context,
                            watchlistService,
                            watchlist,
                          ),
                        ),
                        children: [
                          if (watchlist.items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No items in this watchlist'),
                            )
                          else
                            MediaSectionList(
                              title: '',
                              mediaList: watchlist.items.values
                                  .map((item) => item.item)
                                  .toList(),
                              onLoadMore: null,
                              isLoadingMore: false,
                              watchlistId: watchlist.id,
                            ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      heroTag: 'create_watchlist_fab',
                      onPressed: () => _showCreateWatchlistDialog(context),
                      backgroundColor: Colors.grey[700],
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
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
      builder: (context) => AlertDialog(
        title: const Text('Create New Watchlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter watchlist name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter watchlist description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<WatchlistService>().createWatchlist(
                      nameController.text,
                      descriptionController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWatchlist(
    BuildContext context,
    WatchlistService service,
    Watchlist watchlist,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: Text(
          'Are you sure you want to delete "${watchlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.deleteWatchlist(watchlist.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
