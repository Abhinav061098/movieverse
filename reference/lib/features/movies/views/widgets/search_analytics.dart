import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SearchAnalytics extends StatefulWidget {
  const SearchAnalytics({super.key});

  @override
  State<SearchAnalytics> createState() => _SearchAnalyticsState();
}

class _SearchAnalyticsState extends State<SearchAnalytics> {
  final List<String> _popularSearchTerms = [];
  final Map<int, int> _searchesByHour = {};
  double _searchSuccessRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSearchAnalytics();
  }

  Future<void> _loadSearchAnalytics() async {
    // In a real app, this would fetch data from Firebase Analytics
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _popularSearchTerms
            .addAll(['Action', 'Comedy', 'Thriller', 'Drama', 'Romance']);
        for (int i = 0; i < 24; i++) {
          _searchesByHour[i] = i < 12 ? i + 5 : 20 - i;
        }
        _searchSuccessRate = 0.75;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_popularSearchTerms.isEmpty) {
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
            'Search Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Popular Search Terms',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearchTerms.map((term) {
              return Chip(
                label: Text(term),
                backgroundColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Search Activity by Hour',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
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
                        if (value % 6 == 0) {
                          return Text(
                            '${value.toInt()}:00',
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
                    spots: _searchesByHour.entries
                        .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Search Success Rate',
                  '${(_searchSuccessRate * 100).toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Daily Searches',
                  _searchesByHour.values.reduce((a, b) => a + b).toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
