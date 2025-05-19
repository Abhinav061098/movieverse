import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../../models/watch_provider.dart';
import '../../services/movie_service.dart';
import '../../services/tv_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WatchProvidersDialog extends StatefulWidget {
  final int mediaId;
  final bool isMovie;
  final String title;

  const WatchProvidersDialog({
    super.key,
    required this.mediaId,
    required this.isMovie,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    required int mediaId,
    required bool isMovie,
    required String title,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WatchProvidersDialog(
        mediaId: mediaId,
        isMovie: isMovie,
        title: title,
      ),
    );
  }

  @override
  State<WatchProvidersDialog> createState() => _WatchProvidersDialogState();
}

class _WatchProvidersDialogState extends State<WatchProvidersDialog> {
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        // Fallback to browser if app launch fails
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching URL: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Information'),
                  content: const Text(
                    'We will direct you to the application only, not directly to the item. You can navigate to the specific item via TMDB.',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderGrid(List<WatchProvider> providers) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return GestureDetector(
          onTap: () async {
            // For providers, use search URL
            String? providerUrl;
            final searchQuery = Uri.encodeComponent(widget.title);

            switch (provider.name.toLowerCase()) {
              case 'netflix':
                providerUrl = 'https://www.netflix.com/search?q=$searchQuery';
                break;
              case 'prime video':
              case 'amazon video':
                providerUrl =
                    'https://www.primevideo.com/search?q=$searchQuery';
                break;
              case 'disney+':
                providerUrl =
                    'https://www.disneyplus.com/search?q=$searchQuery';
                break;
              case 'hulu':
                providerUrl = 'https://www.hulu.com/search?q=$searchQuery';
                break;
              case 'hbo max':
                providerUrl = 'https://www.max.com/search?q=$searchQuery';
                break;
              case 'peacock':
                providerUrl = 'https://www.peacocktv.com/search?q=$searchQuery';
                break;
              case 'paramount+':
                providerUrl =
                    'https://www.paramountplus.com/search?q=$searchQuery';
                break;
              case 'apple tv+':
                providerUrl = 'https://tv.apple.com/search?q=$searchQuery';
                break;
              case 'apple tv':
                providerUrl = 'https://tv.apple.com/search?q=$searchQuery';
                break;
              case 'youtube':
                providerUrl =
                    'https://www.youtube.com/results?search_query=$searchQuery';
                break;
              case 'google play movies':
                providerUrl = 'market://search?q=$searchQuery&c=movies';
                break;
              case 'vudu':
                providerUrl = 'https://www.vudu.com/search?q=$searchQuery';
                break;
              case 'microsoft store':
                providerUrl = 'ms-windows-store://search?q=$searchQuery';
                break;
              case 'itunes':
                providerUrl =
                    'itms-apps://itunes.apple.com/search?term=$searchQuery&media=movie';
                break;
              default:
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('${provider.name} Link Not Available'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'We cannot provide a direct link to ${provider.name} at this time.',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'You can still find this title by:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('• Opening the ${provider.name} app directly'),
                          const Text('• Searching for the title in the app'),
                          const Text(
                              '• Visiting the TMDB page for more options'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
                return;
            }

            if (providerUrl != null) {
              await _launchUrl(providerUrl);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.withOpacity(0.1),
            ),
            child: provider.logoPath != null
                ? CachedNetworkImage(
                    imageUrl: provider.fullLogoPath,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.tv,
                      size: 20,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(
                    Icons.tv,
                    size: 20,
                    color: Colors.grey,
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Where to Watch ${widget.title}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, dynamic>>(
                      future: widget.isMovie
                          ? context
                              .read<MovieService>()
                              .getWatchProviders(widget.mediaId)
                          : context
                              .read<TvService>()
                              .getWatchProviders(widget.mediaId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'This title is currently not available to stream anywhere.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        // Extract the results from the response
                        final results =
                            snapshot.data!['results'] as Map<String, dynamic>?;
                        if (results == null || results.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'This title is currently not available to stream anywhere.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        // Try to get US results first, then fall back to other regions
                        Map<String, dynamic>? regionData;
                        if (results.containsKey('US')) {
                          regionData = results['US'];
                        } else {
                          regionData = results.values.first;
                        }

                        if (regionData == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'This title is currently not available to stream anywhere.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        // Parse the watch providers from the region data
                        final providers = WatchProviders.fromJson(regionData);

                        if (!providers.hasAnyProvider) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'This title is currently not available to stream anywhere.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Always show TMDB provider at the top
                            _buildSectionTitle('TMDB'),
                            GestureDetector(
                              onTap: () async {
                                final tmdbUrl =
                                    'https://www.themoviedb.org/${widget.isMovie ? 'movie' : 'tv'}/${widget.mediaId}/watch?locale=US';
                                await _launchUrl(tmdbUrl);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 249, 248, 248)
                                          .withOpacity(1),
                                ),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: SvgPicture.asset(
                                    'assets/svg/tmdb.svg',
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) =>
                                        const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (providers.flatrate.isNotEmpty) ...[
                              _buildSectionTitle('Streaming'),
                              _buildProviderGrid(providers.flatrate),
                              const SizedBox(height: 16),
                            ],
                            if (providers.rent.isNotEmpty) ...[
                              _buildSectionTitle('Rent'),
                              _buildProviderGrid(providers.rent),
                              const SizedBox(height: 16),
                            ],
                            if (providers.buy.isNotEmpty) ...[
                              _buildSectionTitle('Buy'),
                              _buildProviderGrid(providers.buy),
                              const SizedBox(height: 16),
                            ],
                            if (providers.free.isNotEmpty) ...[
                              _buildSectionTitle('Free'),
                              _buildProviderGrid(providers.free),
                              const SizedBox(height: 16),
                            ],
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
