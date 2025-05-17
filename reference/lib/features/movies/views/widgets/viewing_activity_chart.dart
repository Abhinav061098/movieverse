import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:provider/provider.dart';

class ViewingActivityChart extends StatefulWidget {
  const ViewingActivityChart({super.key});

  @override
  State<ViewingActivityChart> createState() => _ViewingActivityChartState();
}

class _ViewingActivityChartState extends State<ViewingActivityChart> {
  late Future<Map<String, int>> _activityData;

  @override
  void initState() {
    super.initState();
    _activityData = _loadViewingActivity();
  }

  Future<Map<String, int>> _loadViewingActivity() async {
    // In a real app, this would fetch data from Firebase Analytics
    // For now, we'll use sample data
    await Future.delayed(const Duration(seconds: 1));
    return {
      'Mon': 5,
      'Tue': 3,
      'Wed': 7,
      'Thu': 4,
      'Fri': 8,
      'Sat': 12,
      'Sun': 10,
    };
  }

  @override
  Widget build(BuildContext context) {
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
            'Your Viewing Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, int>>(
            future: _activityData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;

              // Log chart view
              context.read<FirebaseService>().logEvent('view_activity_chart', {
                'data_points': data.length,
                'timestamp': DateTime.now().toIso8601String(),
              });

              return SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        data.values.reduce((a, b) => a > b ? a : b).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} items\nviewed',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data.keys.elementAt(value.toInt()),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: data.entries.map((entry) {
                      return BarChartGroupData(
                        x: data.keys.toList().indexOf(entry.key),
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.toDouble(),
                            color: Colors.blue,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
