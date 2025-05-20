import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/person_service.dart';
import '../../../../core/api/api_client.dart';
import 'shimmer_widgets.dart';
import '../screens/cast_screen.dart';

class PopularPeopleWidget extends StatefulWidget {
  const PopularPeopleWidget({super.key});

  @override
  State<PopularPeopleWidget> createState() => _PopularPeopleWidgetState();
}

class _PopularPeopleWidgetState extends State<PopularPeopleWidget> {
  late Future<List<dynamic>> _popularPeopleFuture;

  @override
  void initState() {
    super.initState();
    final personService = PersonService(ApiClient());
    _popularPeopleFuture = personService.getPopularPeople();
  }

  void _navigateToCastScreen(
      BuildContext context, Map<String, dynamic> person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CastScreen(
          castId: person['id'],
          name: person['name'] ?? '',
          profilePath: person['profile_path'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'Popular People',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<dynamic>>(
          future: _popularPeopleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerPopularPeopleSection();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final people = snapshot.data!;
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];
                  final profilePath = person['profile_path'];
                  final name = person['name'] ?? '';
                  final knownFor = person['known_for_department'] ?? '';

                  return GestureDetector(
                    onTap: () => _navigateToCastScreen(context, person),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                if (profilePath != null)
                                  CachedNetworkImage(
                                    imageUrl:
                                        'https://image.tmdb.org/t/p/w500$profilePath',
                                    height: 140,
                                    width: 140,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const ShimmerPopularPersonCard(),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      height: 140,
                                      width: 140,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.person,
                                          color: Colors.white54, size: 40),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 140,
                                    width: 140,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.person,
                                        color: Colors.white54, size: 40),
                                  ),
                                // Gradient overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            knownFor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
