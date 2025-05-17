import 'package:flutter/material.dart';
import 'package:movieverse/core/services/firebase_service.dart';
import 'package:provider/provider.dart';

class PopularTimes extends StatefulWidget {
  const PopularTimes({super.key});

  @override
  State<PopularTimes> createState() => _PopularTimesState();
}

class _PopularTimesState extends State<PopularTimes> {
  late Future<List<TimeSlot>> _popularTimes;

  @override
  void initState() {
    super.initState();
    _popularTimes = _loadPopularTimes();
  }

  Future<List<TimeSlot>> _loadPopularTimes() async {
    // In a real app, this would fetch from Firebase Analytics
    // For now, using sample data
    await Future.delayed(const Duration(seconds: 1));
    return [
      TimeSlot(hour: 6, popularity: 0.2),
      TimeSlot(hour: 8, popularity: 0.3),
      TimeSlot(hour: 10, popularity: 0.4),
      TimeSlot(hour: 12, popularity: 0.5),
      TimeSlot(hour: 14, popularity: 0.6),
      TimeSlot(hour: 16, popularity: 0.7),
      TimeSlot(hour: 18, popularity: 0.9),
      TimeSlot(hour: 20, popularity: 1.0),
      TimeSlot(hour: 22, popularity: 0.8),
      TimeSlot(hour: 0, popularity: 0.4),
      TimeSlot(hour: 2, popularity: 0.2),
      TimeSlot(hour: 4, popularity: 0.1),
    ];
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour > 12) return '${hour - 12} PM';
    return '$hour AM';
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
                'Times',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Community Activity',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<TimeSlot>>(
            future: _popularTimes,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final timeSlots = snapshot.data!;

              // Log popular times view
              context.read<FirebaseService>().logEvent('view_popular_times', {
                'timestamp': DateTime.now().toIso8601String(),
              });

              return Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      size: const Size(double.infinity, 150),
                      painter: PopularTimesPainter(timeSlots),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '12 AM',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '12 PM',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '11 PM',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPeakTimeInfo(timeSlots),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeakTimeInfo(List<TimeSlot> timeSlots) {
    final peakSlot = timeSlots.reduce(
      (a, b) => a.popularity > b.popularity ? a : b,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue[300], size: 20),
          const SizedBox(width: 8),
          Text(
            'Peak viewing time: ',
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            _formatHour(peakSlot.hour),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TimeSlot {
  final int hour;
  final double popularity;

  TimeSlot({required this.hour, required this.popularity});
}

class PopularTimesPainter extends CustomPainter {
  final List<TimeSlot> timeSlots;

  PopularTimesPainter(this.timeSlots);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final width = size.width;
    final height = size.height;

    for (var i = 0; i < timeSlots.length; i++) {
      final x = (i / (timeSlots.length - 1)) * width;
      final y = height - (timeSlots[i].popularity * height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient below the line
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.3),
          Colors.blue.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
