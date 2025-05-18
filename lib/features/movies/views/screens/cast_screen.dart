import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:movieverse/core/api/api_client.dart' as api;
import '../../models/cast.dart';
import '../../services/cast_service.dart';

class CastScreen extends StatefulWidget {
  final int castId;
  final String? name;
  final String? profilePath;
  const CastScreen({
    super.key,
    required this.castId,
    this.name,
    this.profilePath,
  });

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen> {
  late Future<Cast> _castFuture;
  late CastService _castService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiClient = api.ApiClient();
    _castService = CastService(apiClient);
    _castFuture = _castService.fetchCastDetails(widget.castId);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double collapsedHeaderHeight = screenHeight * 0.22;
    final double expandedHeaderHeight = screenHeight * 0.45;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<Cast>(
          future: _castFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final cast = snapshot.data!;
            return _ModernCollapsibleCastView(
              cast: cast,
              expandedHeaderHeight: expandedHeaderHeight,
              collapsedHeaderHeight: collapsedHeaderHeight,
            );
          },
        ),
      ),
    );
  }
}

class _ModernCollapsibleCastView extends StatefulWidget {
  final Cast cast;
  final double expandedHeaderHeight;
  final double collapsedHeaderHeight;
  const _ModernCollapsibleCastView({
    required this.cast,
    required this.expandedHeaderHeight,
    required this.collapsedHeaderHeight,
  });
  @override
  State<_ModernCollapsibleCastView> createState() =>
      _ModernCollapsibleCastViewState();
}

class _ModernCollapsibleCastViewState
    extends State<_ModernCollapsibleCastView> {
  double _headerPercent = 1.0;
  late ScrollController _moviesScrollController;
  late ScrollController _tvShowsScrollController;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _moviesScrollController = ScrollController();
    _tvShowsScrollController = ScrollController();
    _moviesScrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController == null) {
      _tabController = DefaultTabController.of(context);
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    _moviesScrollController.removeListener(_onScroll);
    _tvShowsScrollController.removeListener(_onScroll);
    if (_tabController != null && _tabController!.index == 0) {
      if (_moviesScrollController.hasClients) {
        _moviesScrollController.addListener(_onScroll);
        _onScroll();
      }
    } else {
      if (_tvShowsScrollController.hasClients) {
        _tvShowsScrollController.addListener(_onScroll);
        _onScroll();
      }
    }
  }

  void _onScroll() {
    final tabIndex = _tabController?.index ?? 0;
    ScrollController activeController =
        (tabIndex == 0) ? _moviesScrollController : _tvShowsScrollController;
    if (!activeController.hasClients) return;
    final offset = activeController.offset;
    final collapseRange =
        widget.expandedHeaderHeight - widget.collapsedHeaderHeight;
    double percent = 1.0 - (offset / collapseRange);
    percent = percent.clamp(0.2, 1.0);
    setState(() {
      _headerPercent = percent;
    });
  }

  @override
  void dispose() {
    _moviesScrollController.removeListener(_onScroll);
    _tvShowsScrollController.removeListener(_onScroll);
    _moviesScrollController.dispose();
    _tvShowsScrollController.dispose();
    if (_tabController != null) {
      _tabController!.removeListener(_onTabChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = (_headerPercent *
            (widget.expandedHeaderHeight - widget.collapsedHeaderHeight)) +
        widget.collapsedHeaderHeight;
    double infoFade = (_headerPercent - 0.2) / 0.8;
    infoFade = infoFade.clamp(0.0, 1.0);
    double bioFade = (infoFade - 0.5) / 0.5;
    bioFade = bioFade.clamp(0.0, 1.0);
    final cast = widget.cast;
    // Collect poster URLs from movies and tv shows
    final List<String> collageUrls = [
      ...?cast.movies?.map((m) => m.fullPosterPath),
      ...?cast.tvShows?.map((t) => t.fullPosterPath),
    ].where((url) => url.isNotEmpty).cast<String>().toList();
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: headerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Collage background instead of profile image
              if (collageUrls.isNotEmpty)
                CastCollageBackground(
                  posterUrls: collageUrls,
                  opacity: 0.64,
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Hero(
                      tag: 'cast_{cast.name}_{cast.profilePath}',
                      child: CircleAvatar(
                        radius: 54 * _headerPercent + 32 * (1 - _headerPercent),
                        backgroundImage: cast.profilePath != null
                            ? NetworkImage(cast.fullProfilePath)
                            : null,
                        backgroundColor: Colors.grey[900],
                        child: cast.profilePath == null
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cast.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (cast.birthday != null && infoFade > 0)
                            Opacity(
                              opacity: infoFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text('Born: ${cast.birthday!}',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                          if (cast.placeOfBirth != null && infoFade > 0)
                            Opacity(
                              opacity: infoFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text('Place: ${cast.placeOfBirth!}',
                                    style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                          if (cast.biography != null &&
                              cast.biography!.isNotEmpty &&
                              bioFade > 0)
                            Opacity(
                              opacity: bioFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  cast.biography!,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.92)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 0, thickness: 1, color: Colors.white12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                TabBar(
                  indicatorColor: Colors.purpleAccent,
                  labelColor: Colors.purpleAccent,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Movies'),
                    Tab(text: 'TV Shows'),
                  ],
                  onTap: (index) {
                    if (index == 0) {
                      _moviesScrollController.jumpTo(0);
                    } else {
                      _tvShowsScrollController.jumpTo(0);
                    }
                    _onTabChanged();
                  },
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CastMediaGrid(
                        items: cast.movies ?? [],
                        isMovie: true,
                        controller: _moviesScrollController,
                      ),
                      _CastMediaGrid(
                        items: cast.tvShows ?? [],
                        isMovie: false,
                        controller: _tvShowsScrollController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CastCollageBackground extends StatelessWidget {
  final List<String> posterUrls;
  final double opacity;
  const CastCollageBackground(
      {required this.posterUrls, this.opacity = 0.5, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;
    // Calculate how many posters to show based on available space
    final int maxRows = isPortrait ? 3 : 2;
    final int postersPerRow = isPortrait ? 5 : 8;
    final int maxPosters = maxRows * postersPerRow;
    final posters = posterUrls.take(maxPosters).toList();
    final double posterWidth = size.width / postersPerRow;
    final double posterHeight = (size.height * 0.45) / maxRows;

    List<Widget> positionedPosters = [];
    for (int i = 0; i < posters.length; i++) {
      final row = i ~/ postersPerRow;
      final col = i % postersPerRow;
      // Add some random offset and rotation for a collage effect
      final double left =
          col * posterWidth + (row.isEven ? (col % 2) * 8.0 : 0);
      final double top = row * posterHeight + (col.isOdd ? 10.0 : 0);
      final double angle = ((i % 5) - 2) * 0.06;
      positionedPosters.add(Positioned(
        left: left,
        top: top,
        width: posterWidth + 12,
        height: posterHeight + 18,
        child: Transform.rotate(
          angle: angle,
          child: CachedNetworkImage(
            imageUrl: posters[i],
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(opacity),
            colorBlendMode: BlendMode.darken,
          ),
        ),
      ));
    }
    // If not enough posters, fill with empty containers for a smooth look
    int totalSlots = maxRows * postersPerRow;
    for (int i = posters.length; i < totalSlots; i++) {
      final row = i ~/ postersPerRow;
      final col = i % postersPerRow;
      final double left = col * posterWidth;
      final double top = row * posterHeight;
      positionedPosters.add(Positioned(
        left: left,
        top: top,
        width: posterWidth + 12,
        height: posterHeight + 18,
        child: Container(
          color: Colors.black.withOpacity(opacity * 0.7),
        ),
      ));
    }
    return Stack(
      fit: StackFit.expand,
      children: positionedPosters,
    );
  }
}

class _CastMediaGrid extends StatelessWidget {
  final List items;
  final bool isMovie;
  final ScrollController? controller;
  const _CastMediaGrid(
      {required this.items, required this.isMovie, this.controller});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child:
              Text('No items found', style: TextStyle(color: Colors.white70)));
    }
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.only(top: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (isMovie) {
              Navigator.pushNamed(
                context,
                '/movieDetails',
                arguments: item.id,
              );
            } else {
              Navigator.pushNamed(
                context,
                '/tvShowDetails',
                arguments: item.id,
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl:
                        isMovie ? item.fullPosterPath : item.fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child:
                          const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
