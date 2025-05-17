import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Update the import below to your actual MediaItem location
import '../../models/media_item.dart';
// You may need to update AuthService import to your actual path
// import '../../../../core/services/auth_service.dart';

class Comment {
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  int likes;

  Comment({
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    this.likes = 0,
  });
}

class MovieDiscussionWidget extends StatefulWidget {
  final MediaItem mediaItem;

  const MovieDiscussionWidget({super.key, required this.mediaItem});

  @override
  State<MovieDiscussionWidget> createState() => _MovieDiscussionWidgetState();
}

class _MovieDiscussionWidgetState extends State<MovieDiscussionWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isExpanded = true;
  final List<Comment> _comments = [];

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // TODO: Replace with your actual AuthService logic
    // final user = context.read<AuthService>().currentUser;
    final user = null; // Placeholder
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    setState(() {
      _comments.insert(
        0,
        Comment(
          userId: 'user.uid', // Replace with user.uid
          userName: 'Anonymous', // Replace with user.email or displayName
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        children: [
          ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text('Discussion',
                    style: Theme.of(context).textTheme.titleLarge),
              );
            },
            body: Column(
              children: [
                for (final comment in _comments)
                  ListTile(
                    title: Text(comment.userName),
                    subtitle: Text(comment.text),
                    trailing: Text(
                        '${comment.timestamp.hour}:${comment.timestamp.minute}'),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                              hintText: 'Add a comment...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            isExpanded: _isExpanded,
          ),
        ],
      ),
    );
  }
}
