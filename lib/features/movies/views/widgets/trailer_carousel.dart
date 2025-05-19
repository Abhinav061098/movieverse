import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie_trailer.dart';

class TrailerCarousel extends StatefulWidget {
  final List<MovieTrailer> trailers;

  const TrailerCarousel({super.key, required this.trailers});

  @override
  State<TrailerCarousel> createState() => _TrailerCarouselState();
}

class _TrailerCarouselState extends State<TrailerCarousel>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  YoutubePlayerController? _activeController;
  int _currentIndex = 0;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializePlayer(0);
  }

  Future<void> _initializePlayer(int index) async {
    if (index < 0 || index >= widget.trailers.length || _isDisposed) return;

    // Dispose previous controller if exists
    await _activeController?.close();

    // Create new controller with a slight delay to prevent frame drops
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted || _isDisposed) return;

    try {
      // Create new controller
      _activeController = YoutubePlayerController.fromVideoId(
        videoId: widget.trailers[index].videoId,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableJavaScript: true,
          playsInline: true,
          showVideoAnnotations: false,
        ),
      );

      // Add listener for video state
      _activeController?.listen((event) {
        if (event.playerState == PlayerState.ended && mounted && !_isDisposed) {
          final nextIndex = (_currentIndex + 1) % widget.trailers.length;
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _handlePageChange(int index) async {
    if (_currentIndex == index || _isDisposed) return;

    setState(() {
      _currentIndex = index;
      _isInitialized = false;
    });

    await _initializePlayer(index);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _activeController?.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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

              if (!isActive || !_isInitialized) {
                return CachedNetworkImage(
                  imageUrl:
                      'https://img.youtube.com/vi/${trailer.videoId}/maxresdefault.jpg',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.error),
                  ),
                );
              }

              return YoutubePlayerScaffold(
                controller: _activeController!,
                aspectRatio: 16 / 9,
                builder: (context, player) {
                  return player;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
