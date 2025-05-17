import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ContentPerformance extends StatefulWidget {
  const ContentPerformance({super.key});

  @override
  State<ContentPerformance> createState() => _ContentPerformanceState();
}

class _ContentPerformanceState extends State<ContentPerformance> {
  final Map<String, int> _genreViews = {};
  final Map<String, double> _completionRates = {};
  double _averageWatchTime = 0;

  @override
  void initState() {
    super.initState();
    _loadContentMetrics();
  }

  Future<void> _loadContentMetrics() async {
    // Simulated data - would be fetched from Firebase Analytics in production
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _genreViews.addAll({
          'Action': 1200,
          'Drama': 800,
          'Comedy': 950,
          'Horror': 500,
          'Romance': 600,
        });

        _completionRates.addAll({
          'Movies': 0.85,
          'TV Episodes': 0.78,
        });

        _averageWatchTime = 87; // minutes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_genreViews.isEmpty) {
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
            'Content Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Most Viewed Genres',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _genreViews.values
                    .reduce((a, b) => a > b ? a : b)
                    .toDouble(),
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
                        if (value >= 0 && value < _genreViews.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _genreViews.keys.elementAt(value.toInt()),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: _genreViews.entries.map((entry) {
                  return BarChartGroupData(
                    x: _genreViews.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildCompletionRateCard(
                  'Movie Completion',
                  _completionRates['Movies'] ?? 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompletionRateCard(
                  'TV Episode Completion',
                  _completionRates['TV Episodes'] ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
            'Average Watch Time',
            '${_averageWatchTime.toStringAsFixed(0)} min',
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(String title, double rate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate,
                backgroundColor: Colors.grey[700],
                color: Colors.blue,
              ),
              Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
