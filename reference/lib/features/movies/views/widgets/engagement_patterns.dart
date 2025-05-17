import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EngagementPatterns extends StatefulWidget {
  const EngagementPatterns({super.key});

  @override
  State<EngagementPatterns> createState() => _EngagementPatternsState();
}

class _EngagementPatternsState extends State<EngagementPatterns> {
  final List<List<double>> _sessionHeatmap = List.generate(
    7, // days
    (i) => List.generate(24, (j) => 0), // hours
  );
  final Map<String, double> _featureUsage = {};
  final List<double> _dailyActiveUsers = [];

  @override
  void initState() {
    super.initState();
    _loadEngagementData();
  }

  Future<void> _loadEngagementData() async {
    // Simulated data - would be fetched from Firebase Analytics in production
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // Generate heatmap data
        for (int i = 0; i < 7; i++) {
          for (int j = 0; j < 24; j++) {
            _sessionHeatmap[i][j] = (i * j % 10).toDouble() / 10;
          }
        }

        // Feature usage data
        _featureUsage.addAll({
          'Search': 0.35,
          'Favorites': 0.25,
          'Watchlist': 0.20,
          'Recommendations': 0.15,
          'Profile': 0.05,
        });

        // Daily active users for the past week
        _dailyActiveUsers.addAll([120, 145, 132, 160, 138, 142, 155]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_featureUsage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Patterns',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Session Heatmap',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildHeatmap(),
          ),
          const SizedBox(height: 24),
          Text(
            'Feature Usage',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _featureUsage.entries.map((entry) {
                  return PieChartSectionData(
                    color: Colors.blue.withOpacity(0.5 + entry.value),
                    value: entry.value * 100,
                    title:
                        '${entry.key}\n${(entry.value * 100).toStringAsFixed(0)}%',
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Daily Active Users',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        if (value >= 0 && value < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyActiveUsers.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 24, // hours
        childAspectRatio: 1,
      ),
      itemCount: 7 * 24, // days * hours
      itemBuilder: (context, index) {
        final day = index ~/ 24;
        final hour = index % 24;
        final intensity = _sessionHeatmap[day][hour];
        return Tooltip(
          message: '${days[day]} $hour:00 - ${hour + 1}:00\n'
              'Activity: ${(intensity * 100).toStringAsFixed(0)}%',
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(intensity),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
