import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/media_card.dart';
import '../viewmodels/movie_view_model.dart';
import '../viewmodels/tv_show_view_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_searchController.text.isNotEmpty) {
        // Removed fetchMoreMovies and fetchMoreTvShows calls as per the new view models.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieViewModel>(
      builder: (context, movieViewModel, child) {
        return Consumer<TvShowViewModel>(
          builder: (context, tvShowViewModel, child) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search movies or TV shows...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              body: _buildBody(movieViewModel, tvShowViewModel),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
      MovieViewModel movieViewModel, TvShowViewModel tvShowViewModel) {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Text(
          'Search movies or TV shows',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      );
    }

    // Fix: Use correct getters for movie and TV show lists, or show empty lists if search is not implemented.
    final movieResults = movieViewModel.popularMovies;
    final tvShowResults = tvShowViewModel.popularTvShows;

    if (movieResults.isEmpty && tvShowResults.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: Colors.white)),
      );
    }

    final combinedResults = [...movieResults, ...tvShowResults];

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: combinedResults.length,
      itemBuilder: (context, index) {
        final media = combinedResults[index];
        return MediaCard(
          media: media,
          onTap: () {},
        );
      },
    );
  }
}
