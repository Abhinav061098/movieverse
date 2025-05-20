import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/mood_movie_service.dart';
import '../../models/mood_movie_data.dart';

class MoodMovieMap extends StatefulWidget {
  final MoodMovieService moodMovieService;

  const MoodMovieMap({
    super.key,
    required this.moodMovieService,
  });

  @override
  State<MoodMovieMap> createState() => _MoodMovieMapState();
}

class _MoodMovieMapState extends State<MoodMovieMap>
    with SingleTickerProviderStateMixin {
  late Future<MoodMovieData> _moodMovieData;
  int? _touchedIndex;
  final PageController _pageController = PageController(initialPage: 0);
  late AnimationController _animationController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('\n=== INITIALIZING MOOD MOVIE MAP ===');
    _moodMovieData = widget.moodMovieService.getMoodMovieData();
    debugPrint('MoodMovieData future created');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MoodMovieData>(
      future: _moodMovieData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('No data available'),
          );
        }

        final data = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            // Use a fixed height if parent provides unbounded height
            final height = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height *
                    0.7; // 70% of screen height

            return SizedBox(
              height: height,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPageIndicator(0, 'Genre Distribution'),
                        const SizedBox(width: 16),
                        _buildPageIndicator(1, 'Movie Persona'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildGenreDistributionCard(data),
                        _buildPersonaAnalysis(data.genreCounts),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPageIndicator(int pageIndex, String label) {
    final isSelected = _currentPage == pageIndex;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGenreDistributionCard(MoodMovieData data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genre Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: _buildMoodGenreChart(data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaAnalysis(Map<String, int> genreCounts) {
    final groupPercentages = _calculatePersonaGroups(genreCounts);
    final persona = _assignPersona(groupPercentages);
    final personaInfo = _getPersonaInfo(persona);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Movie Persona',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text('How it works?'),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInfoSection(
                                'Genre Groups',
                                [
                                  'Emotional: Drama, Family, Romance',
                                  'Dark & Gritty: Crime, Mystery, Thriller',
                                  'Escapist: Adventure, Fantasy, Sci-Fi',
                                  'Realist: Documentary, History',
                                  'Fun: Animation, Comedy',
                                  'Adrenaline: Action, War, Western',
                                  'Fear: Horror',
                                  'Nostalgic: Music, TV Movie',
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoSection(
                                'Calculation',
                                [
                                  'Each movie\'s genres contribute to their respective groups',
                                  'Percentages are calculated based on total genre appearances',
                                  'If you have multiple strong preferences, you get a hybrid persona',
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildInfoSection(
                                'No Genres?',
                                [
                                  'Add movies to your watchlist',
                                  'Rate your favorite movies',
                                  'The more you watch, the more accurate your persona becomes!',
                                ],
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Got it!'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Hero(
                  tag: 'persona_icon',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPersonaIcon(persona),
                      size: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personaInfo['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Genre Group Distribution',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: groupPercentages.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text('${entry.value.toStringAsFixed(1)}%'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: entry.value / 100,
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(point)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMoodGenreChart(MoodMovieData data) {
    if (data.genreCounts.isEmpty) {
      return const Center(
        child: Text('No genre data available'),
      );
    }

    final totalCount =
        data.genreCounts.values.fold<int>(0, (sum, count) => sum + count);
    final sortedGenres = data.genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate max value and round it up to the next multiple of 5
    final maxValue = sortedGenres.first.value;
    final roundedMax = ((maxValue + 4) ~/ 5) * 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genre Distribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: roundedMax.toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final genre = sortedGenres[groupIndex];
                        final percentage =
                            (genre.value / totalCount * 100).toStringAsFixed(1);
                        return BarTooltipItem(
                          '${genre.key}\n${genre.value} (${percentage}%)',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: roundedMax > 20 ? 5.0 : 1.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: sortedGenres.asMap().entries.map((entry) {
                    final index = entry.key;
                    final genre = entry.value;
                    final isSelected = index == _touchedIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: genre.value.toDouble(),
                          color: _getColorForIndex(index),
                          width: isSelected ? 30 : 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: isSelected ? [0] : [],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sortedGenres.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildGenreItem(
                        sortedGenres[i],
                        i,
                        totalCount,
                        _getColorForIndex(i),
                        onTap: () {
                          setState(() {
                            _touchedIndex = _touchedIndex == i ? null : i;
                          });
                        },
                      ),
                    ),
                    if (i + 1 < sortedGenres.length)
                      Expanded(
                        child: _buildGenreItem(
                          sortedGenres[i + 1],
                          i + 1,
                          totalCount,
                          _getColorForIndex(i + 1),
                          onTap: () {
                            setState(() {
                              _touchedIndex =
                                  _touchedIndex == i + 1 ? null : i + 1;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenreItem(
    MapEntry<String, int> entry,
    int index,
    int totalCount,
    Color color, {
    required VoidCallback onTap,
  }) {
    final isTouched = index == _touchedIndex;
    final percentage = (entry.value / totalCount * 100).toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTouched ? 8.0 : 0),
        decoration: BoxDecoration(
          color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTouched ? 20 : 16,
              height: isTouched ? 20 : 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isTouched
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isTouched ? FontWeight.bold : FontWeight.normal,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isTouched
                                  ? color
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: isTouched
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ) ??
                        const TextStyle(),
                    child: Text(
                      isTouched
                          ? '${entry.value} (${percentage}%)'
                          : '$percentage%',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(
      Map<String, int> genreCounts) {
    final totalCount =
        genreCounts.values.fold<int>(0, (sum, count) => sum + count);
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedGenres.map((entry) {
      final index = sortedGenres.indexOf(entry);
      final isTouched = index == _touchedIndex;
      final percentage = (entry.value / totalCount * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: isTouched ? '${entry.key}\n$percentage%' : '',
        color: _getColorForIndex(index),
        radius: isTouched ? 110 : 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFF44336),
    ];
    return colors[index % colors.length];
  }

  Map<String, double> _calculatePersonaGroups(Map<String, int> genreCounts) {
    final Map<String, int> groupCounts = {};
    final Map<int, String> genreToGroup = {
      28: 'Adrenaline', // Action
      12: 'Escapist', // Adventure
      16: 'Fun', // Animation
      35: 'Fun', // Comedy
      80: 'Dark & Gritty', // Crime
      99: 'Realist', // Documentary
      18: 'Emotional', // Drama
      10751: 'Emotional', // Family
      14: 'Escapist', // Fantasy
      36: 'Realist', // History
      27: 'Fear', // Horror
      10402: 'Nostalgic', // Music
      9648: 'Dark & Gritty', // Mystery
      10749: 'Emotional', // Romance
      878: 'Escapist', // Sci-Fi
      10770: 'Nostalgic', // TV Movie
      53: 'Dark & Gritty', // Thriller
      10752: 'Adrenaline', // War
      37: 'Adrenaline', // Western
    };

    genreCounts.forEach((genre, count) {
      final genreId = _getGenreId(genre);
      if (genreId != null) {
        final group = genreToGroup[genreId];
        if (group != null) {
          groupCounts[group] = (groupCounts[group] ?? 0) + count;
        }
      }
    });

    final total = groupCounts.values.fold(0, (sum, c) => sum + c);
    if (total == 0) return {};

    final Map<String, double> normalized = {};
    groupCounts.forEach((group, count) {
      normalized[group] = (count / total) * 100;
    });

    return normalized;
  }

  String _assignPersona(Map<String, double> groupPercentages) {
    if (groupPercentages.isEmpty) return 'Unknown';

    final sorted = groupPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top1 = sorted[0];
    final top2 = sorted.length > 1 ? sorted[1] : null;

    const double hybridThreshold = 20.0;

    if (top2 != null &&
        top1.value >= hybridThreshold &&
        top2.value >= hybridThreshold) {
      final persona1 = _getPersonaName(top1.key);
      final persona2 = _getPersonaName(top2.key);
      return '$persona1 - $persona2 (Hybrid)';
    } else {
      return _getPersonaName(top1.key);
    }
  }

  String _getPersonaName(String group) {
    const Map<String, String> personaNames = {
      'Emotional': 'The Empath',
      'Dark & Gritty': 'The Shadow Thinker',
      'Escapist': 'The Dream Walker',
      'Realist': 'The Truth Seeker',
      'Fun': 'The Joy Bringer',
      'Adrenaline': 'The Thrill Hunter',
      'Fear': 'The Edge Dancer',
      'Nostalgic': 'The Nostalgic',
    };
    return personaNames[group] ?? group;
  }

  Map<String, String> _getPersonaInfo(String persona) {
    const Map<String, Map<String, String>> personaInfo = {
      'The Empath': {
        'description': 'Deeply connects with feelings and relationships.',
        'icon': 'heart',
      },
      'The Shadow Thinker': {
        'description': 'Loves mysteries, crime, and moral complexity.',
        'icon': 'psychology',
      },
      'The Dream Walker': {
        'description': 'Imaginative, loves fantasy and sci-fi escapes.',
        'icon': 'auto_awesome',
      },
      'The Truth Seeker': {
        'description': 'Values facts, documentaries, and history.',
        'icon': 'lightbulb',
      },
      'The Joy Bringer': {
        'description': 'Enjoys humor, lightheartedness, and fun stories.',
        'icon': 'sentiment_very_satisfied',
      },
      'The Thrill Hunter': {
        'description': 'Thrill-seeking and loves action-packed stories.',
        'icon': 'bolt',
      },
      'The Edge Dancer': {
        'description': 'Attracted to suspense, horror, and tension.',
        'icon': 'nightlight',
      },
      'The Nostalgic': {
        'description': 'Drawn to sentimentality, music, and retro themes.',
        'icon': 'history',
      },
    };

    // Handle hybrid personas
    if (persona.contains(' - ')) {
      return {
        'description': 'A unique blend of different movie preferences.',
        'icon': 'blend',
      };
    }

    return personaInfo[persona] ??
        {
          'description': 'Your unique movie watching style.',
          'icon': 'person',
        };
  }

  IconData _getPersonaIcon(String persona) {
    const Map<String, IconData> personaIcons = {
      'The Empath': Icons.favorite,
      'The Shadow Thinker': Icons.psychology,
      'The Dream Walker': Icons.auto_awesome,
      'The Truth Seeker': Icons.lightbulb,
      'The Joy Bringer': Icons.sentiment_very_satisfied,
      'The Thrill Hunter': Icons.bolt,
      'The Edge Dancer': Icons.nightlight,
      'The Nostalgic': Icons.history,
    };

    if (persona.contains(' - ')) {
      return Icons.merge_type;
    }

    return personaIcons[persona] ?? Icons.person;
  }

  int? _getGenreId(String genreName) {
    const Map<String, int> genreNameToId = {
      'Action': 28,
      'Adventure': 12,
      'Animation': 16,
      'Comedy': 35,
      'Crime': 80,
      'Documentary': 99,
      'Drama': 18,
      'Family': 10751,
      'Fantasy': 14,
      'History': 36,
      'Horror': 27,
      'Music': 10402,
      'Mystery': 9648,
      'Romance': 10749,
      'Sci-Fi': 878,
      'TV Movie': 10770,
      'Thriller': 53,
      'War': 10752,
      'Western': 37,
    };
    return genreNameToId[genreName];
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: borderColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
