import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie_trailer.dart';

class TrailerCarousel extends StatefulWidget {
  final List<MovieTrailer> trailers;

  const TrailerCarousel({Key? key, required this.trailers}) : super(key: key);

  @override
  State<TrailerCarousel> createState() => _TrailerCarouselState();
}

class _TrailerCarouselState extends State<TrailerCarousel> {
  late final PageController _pageController;
  YoutubePlayerController? _activeController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializePlayer(_currentIndex);
  }

  Future<void> _initializePlayer(int index) async {
    if (index < 0 || index >= widget.trailers.length) return;

    // Dispose previous controller if exists
    await _activeController?.close();

    // Create new controller with a slight delay to prevent frame drops
    await Future.delayed(const Duration(milliseconds: 150));

    // Create new controller
    _activeController = YoutubePlayerController.fromVideoId(
      videoId: widget.trailers[index].videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableJavaScript: true,
        playsInline: true,
      ),
    );

    // Add listener for video state
    _activeController?.listen((event) {
      if (event.playerState == PlayerState.ended) {
        final nextIndex = (_currentIndex + 1) % widget.trailers.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  void _handlePageChange(int index) async {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    await _initializePlayer(index);
  }

  @override
  void dispose() {
    _activeController?.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trailers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Latest Trailers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1}/${widget.trailers.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9 / 16,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.trailers.length,
            onPageChanged: _handlePageChange,
            itemBuilder: (context, index) {
              final trailer = widget.trailers[index];
              final isActive = index == _currentIndex;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail
                        CachedNetworkImage(
                          imageUrl:
                              'https://img.youtube.com/vi/${trailer.videoId}/maxresdefault.jpg',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.black54,
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                        // YouTube Player
                        if (isActive && _activeController != null)
                          YoutubePlayer(
                            controller: _activeController!,
                            aspectRatio: 16 / 9,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
