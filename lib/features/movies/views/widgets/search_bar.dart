import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClear;
  final List<String> searchHistory;
  final VoidCallback onClearHistory;

  const CustomSearchBar({
    super.key,
    required this.onSearch,
    required this.onClear,
    required this.searchHistory,
    required this.onClearHistory,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search movies and TV shows...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onClear();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onSubmitted: widget.onSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
        if (widget.searchHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8.0,
            children: widget.searchHistory.map((term) {
              return Chip(
                label: Text(term),
                onDeleted: () {
                  _controller.text = term;
                  widget.onSearch(term);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
