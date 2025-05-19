import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/movie_details_screen.dart';
import '../screens/tv_show_details_screen.dart';
import '../../models/director.dart';
import '../../models/movie.dart';
import '../../models/tv_show.dart';
import '../../services/director_service.dart';
import '../widgets/cast_director_shimmer_widgets.dart';
import 'package:movieverse/core/api/api_client.dart' as api;

class DirectorScreen extends StatefulWidget {
  final int directorId;
  final String? name;
  final String? profilePath;
  const DirectorScreen({
    super.key,
    required this.directorId,
    this.name,
    this.profilePath,
  });

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  late Future<Director> _directorFuture;
  late DirectorService _directorService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiClient = api.ApiClient();
    _directorService = DirectorService(apiClient);
    _directorFuture = _directorService.getDirectorDetails(widget.directorId);
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
        body: FutureBuilder<Director>(
          future: _directorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  ShimmerDirectorHeader(height: expandedHeaderHeight),
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
                          ),
                          const Expanded(
                            child: ShimmerMediaGrid(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final director = snapshot.data!;
            return _CollapsibleDirectorView(
              director: director,
              movies: director.movieCredits ?? [],
              tvShows: director.tvCredits ?? [],
            );
          },
        ),
      ),
    );
  }
}

class _CollapsibleDirectorView extends StatefulWidget {
  final Director director;
  final List<Movie> movies;
  final List<TvShow> tvShows;
  const _CollapsibleDirectorView({
    required this.director,
    required this.movies,
    required this.tvShows,
  });
  @override
  State<_CollapsibleDirectorView> createState() =>
      _CollapsibleDirectorViewState();
}

class _CollapsibleDirectorViewState extends State<_CollapsibleDirectorView> {
  double _headerPercent = 1.0;
  final double minHeaderPercent = 0.2;
  final double maxHeaderHeight = 300;
  final double minHeaderHeight = 60;
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
      _moviesScrollController.addListener(_onScroll);
      _onScroll();
    } else {
      _tvShowsScrollController.addListener(_onScroll);
      _onScroll();
    }
  }

  void _onScroll() {
    ScrollController activeController = (_tabController?.index == 0)
        ? _moviesScrollController
        : _tvShowsScrollController;
    final offset = activeController.offset;
    final collapseRange = maxHeaderHeight - minHeaderHeight;
    double percent = 1.0 - (offset / collapseRange);
    percent = percent.clamp(minHeaderPercent, 1.0);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final double collapsedHeaderHeight = screenHeight * 0.25;
    final double expandedHeaderHeight = maxHeaderHeight;
    final double headerHeight =
        (_headerPercent * (expandedHeaderHeight - collapsedHeaderHeight)) +
            collapsedHeaderHeight;

    // Calculate fade-out for info fields with smoother transitions
    double infoFade =
        (_headerPercent - minHeaderPercent) / (1.0 - minHeaderPercent);
    infoFade = infoFade.clamp(0.0, 1.0);

    // Ensure values stay within [0, 1] range before applying curve
    double bornPlaceFade = ((infoFade - 0.0) / 0.5).clamp(0.0, 1.0);
    double bioFade = ((infoFade - 0.5) / 0.5).clamp(0.0, 1.0);

    // Apply curve after clamping
    bornPlaceFade = Curves.easeInOut.transform(bornPlaceFade);
    bioFade = Curves.easeInOut.transform(bioFade);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(
              milliseconds: 200), // Increased duration for smoother animation
          curve: Curves.easeInOut, // Added curve for smoother animation
          height: headerHeight,
          child: Row(
            children: [
              // Responsive Director Image
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          16 * _headerPercent + 8 * (1 - _headerPercent)),
                      child: widget.director.profilePath != null
                          ? CachedNetworkImage(
                              imageUrl: widget.director.fullProfilePath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.person, size: 60),
                              ),
                            )
                          : Container(
                              color: Colors.grey[900],
                              child: const Icon(Icons.person, size: 60),
                            ),
                    ),
                  ),
                ),
              ),
              // Responsive Director Info
              Expanded(
                flex: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontSize: 24 * _headerPercent +
                                      18 * (1 - _headerPercent),
                                ),
                        child: Text(
                          widget.director.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.director.knownForDepartment != null &&
                          bioFade > 0)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          opacity: bioFade,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              widget.director.knownForDepartment!,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      if (widget.director.biography != null &&
                          widget.director.biography!.isNotEmpty &&
                          bioFade > 0)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          opacity: bioFade,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              widget.director.biography!,
                              maxLines: (6 * _headerPercent).round(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                          ),
                        ),
                      if (widget.director.birthday != null && bornPlaceFade > 0)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          opacity: bornPlaceFade,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Born: ${widget.director.birthday!}'),
                          ),
                        ),
                      if (widget.director.placeOfBirth != null &&
                          bornPlaceFade > 0)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          opacity: bornPlaceFade,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child:
                                Text('Place: ${widget.director.placeOfBirth!}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DefaultTabController(
              length: 2,
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      TabBar(
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
                            _MediaGrid(
                              items: widget.movies,
                              isMovie: true,
                              controller: _moviesScrollController,
                            ),
                            _MediaGrid(
                              items: widget.tvShows,
                              isMovie: false,
                              controller: _tvShowsScrollController,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List items;
  final bool isMovie;
  final ScrollController? controller;
  const _MediaGrid(
      {required this.items, required this.isMovie, this.controller});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movieId: item.id),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TvShowDetailsScreen(tvShowId: item.id),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        isMovie ? item.fullPosterPath : item.fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image),
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
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}
