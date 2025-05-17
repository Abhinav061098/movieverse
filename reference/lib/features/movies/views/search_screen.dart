import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/media_card.dart';
import '../viewmodels/media_list_viewmodel.dart';

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
      final viewModel = context.read<MediaListViewModel>();
      viewModel.loadMoreSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaListViewModel>(
      builder: (context, viewModel, child) {
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
                hintText:
                    'Search ${viewModel.selectedMediaType == MediaType.movie ? 'movies' : 'TV shows'}...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.stopSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (query) => viewModel.search(query),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  viewModel.selectedMediaType == MediaType.movie
                      ? Icons.movie
                      : Icons.tv,
                  color: Colors.white,
                ),
                onPressed: () {
                  viewModel.setMediaType(
                    viewModel.selectedMediaType == MediaType.movie
                        ? MediaType.tvShow
                        : MediaType.movie,
                  );
                  if (_searchController.text.isNotEmpty) {
                    viewModel.search(_searchController.text);
                  }
                },
              ),
            ],
          ),
          body: _buildBody(viewModel),
        );
      },
    );
  }

  Widget _buildBody(MediaListViewModel viewModel) {
    if (_searchController.text.isEmpty) {
      return _buildSearchHistory(viewModel);
    }

    if (viewModel.state == MediaListState.loading &&
        viewModel.searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (viewModel.state == MediaListState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.error,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.search(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.searchResults.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: Colors.white)),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: viewModel.searchResults.length +
          (viewModel.isLoadingMoreSearch ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == viewModel.searchResults.length) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        final media = viewModel.searchResults[index];
        return MediaCard(
          media: media.item,
          onTap: () => viewModel.navigateToDetails(context, media.item),
        );
      },
    );
  }

  Widget _buildSearchHistory(MediaListViewModel viewModel) {
    if (viewModel.searchHistory.isEmpty) {
      return Center(
        child: Text(
          'Search ${viewModel.selectedMediaType == MediaType.movie ? 'movies' : 'TV shows'}',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: viewModel.clearSearchHistory,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.searchHistory.length,
            itemBuilder: (context, index) {
              final query = viewModel.searchHistory[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InputChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    viewModel.search(query);
                  },
                  onDeleted: () {
                    List<String> newHistory = List.from(
                      viewModel.searchHistory,
                    );
                    newHistory.removeAt(index);
                    viewModel.updateSearchHistory(newHistory);
                  },
                  backgroundColor: Colors.grey[800],
                  labelStyle: const TextStyle(color: Colors.white),
                  deleteIconColor: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
