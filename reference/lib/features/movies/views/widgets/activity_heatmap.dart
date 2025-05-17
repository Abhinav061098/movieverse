import 'package:flutter/material.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:provider/provider.dart';

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key});

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  final List<String> _daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  final List<String> _timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];
  late Future<Map<String, Map<String, int>>> _heatmapData;

  @override
  void initState() {
    super.initState();
    _heatmapData = _loadActivityData();
  }

  Future<Map<String, Map<String, int>>> _loadActivityData() async {
    // In a real app, this would fetch from Firebase Analytics
    // For now, using sample data
    await Future.delayed(const Duration(seconds: 1));
    return {
      'Mon': {'Morning': 2, 'Afternoon': 3, 'Evening': 5, 'Night': 4},
      'Tue': {'Morning': 1, 'Afternoon': 4, 'Evening': 6, 'Night': 3},
      'Wed': {'Morning': 3, 'Afternoon': 2, 'Evening': 7, 'Night': 5},
      'Thu': {'Morning': 2, 'Afternoon': 5, 'Evening': 4, 'Night': 6},
      'Fri': {'Morning': 4, 'Afternoon': 6, 'Evening': 8, 'Night': 7},
      'Sat': {'Morning': 5, 'Afternoon': 7, 'Evening': 9, 'Night': 8},
      'Sun': {'Morning': 4, 'Afternoon': 8, 'Evening': 7, 'Night': 6},
    };
  }

  Color _getIntensityColor(int value) {
    final maxValue = 9;
    final intensity = value / maxValue;
    return Colors.blue.withOpacity(intensity);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity Pattern',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Tooltip(
                message: 'Darker color indicates higher activity',
                child: Icon(Icons.info_outline, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<Map<String, Map<String, int>>>(
            future: _heatmapData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;

              // Log heatmap view
              context
                  .read<FirebaseService>()
                  .logEvent('view_activity_heatmap', {
                'timestamp': DateTime.now().toIso8601String(),
              });

              return Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 80),
                      ...List.generate(_daysOfWeek.length, (index) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              _daysOfWeek[index],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_timeSlots.length, (timeIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              _timeSlots[timeIndex],
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ...List.generate(_daysOfWeek.length, (dayIndex) {
                            final value = data[_daysOfWeek[dayIndex]]![
                                _timeSlots[timeIndex]]!;
                            return Expanded(
                              child: Center(
                                child: Container(
                                  height: 30,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _getIntensityColor(value),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Tooltip(
                                    message: '$value views',
                                    child: const SizedBox(),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
