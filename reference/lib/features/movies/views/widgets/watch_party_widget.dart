import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/media_item.dart';

class WatchPartyWidget extends StatefulWidget {
  final MediaItem mediaItem;

  const WatchPartyWidget({super.key, required this.mediaItem});

  @override
  State<WatchPartyWidget> createState() => _WatchPartyWidgetState();
}

class _WatchPartyWidgetState extends State<WatchPartyWidget> {
  final List<String> _participants = [];
  bool _isPartyActive = false;
  final TextEditingController _inviteController = TextEditingController();

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
                'Watch Party',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Switch(
                value: _isPartyActive,
                onChanged: (value) {
                  if (context.read<AuthService>().currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to start a watch party'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isPartyActive = value;
                  });
                },
              ),
            ],
          ),
          if (_isPartyActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inviteController,
                    decoration: const InputDecoration(
                      hintText: 'Enter friend\'s email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final email = _inviteController.text.trim();
                    if (email.isNotEmpty) {
                      setState(() {
                        _participants.add(email);
                        _inviteController.clear();
                      });
                    }
                  },
                  child: const Text('Invite'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Participants:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _participants.map((email) {
                return Chip(
                  label: Text(email),
                  onDeleted: () {
                    setState(() {
                      _participants.remove(email);
                    });
                  },
                );
              }).toList(),
            ),
            if (_participants.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // In a real app, this would start the synchronized playback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Watch party started!'),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Watching'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
