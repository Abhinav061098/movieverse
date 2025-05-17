import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../features/movies/services/favorites_service.dart';
import '../../../features/movies/models/media_item.dart';
import '../../../features/movies/views/widgets/media_section_list.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final email = user?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthService>().signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Consumer<FavoritesService>(
            builder: (context, favoritesService, child) {
              return StreamBuilder<List<MediaItem>>(
                stream: favoritesService.favoritesStream,
                initialData: const [],
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No favorites yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  // Split favorites into movies and TV shows
                  final movies = snapshot.data!
                      .where((item) => item.item.mediaType == 'movie')
                      .map((f) => f.item)
                      .toList();

                  final tvShows = snapshot.data!
                      .where((item) => item.item.mediaType == 'tv')
                      .map((f) => f.item)
                      .toList();

                  return Column(
                    children: [
                      if (movies.isNotEmpty)
                        MediaSectionList(
                          title: 'Favorite Movies',
                          mediaList: movies,
                          isLoadingMore: false,
                        ),
                      if (tvShows.isNotEmpty)
                        MediaSectionList(
                          title: 'Favorite TV Shows',
                          mediaList: tvShows,
                          isLoadingMore: false,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
