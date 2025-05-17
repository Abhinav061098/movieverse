import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// Update the import below to your actual MediaItem location
import '../../models/media_item.dart';
// You may need to update AuthService import to your actual path
// import '../../../../core/services/auth_service.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String text;
  final DateTime timestamp;
  final bool edited;
  final String? parentId;
  final List<String> likes;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.text,
    required this.timestamp,
    this.edited = false,
    this.parentId,
    this.likes = const [],
  });

  factory Comment.fromSnapshot(DataSnapshot snap) {
    final data = Map<String, dynamic>.from(snap.value as Map);
    return Comment(
      id: snap.key ?? '',
      userId: data['userId'],
      userName: data['userName'],
      userAvatarUrl: data['userAvatarUrl'] ?? '',
      text: data['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
      edited: data['edited'] ?? false,
      parentId: data['parentId'],
      likes: data['likes'] != null ? List<String>.from(data['likes']) : [],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userAvatarUrl': userAvatarUrl,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'edited': edited,
        'parentId': parentId,
        'likes': likes,
      };
}

class MovieDiscussionWidget extends StatefulWidget {
  final MediaItem mediaItem;

  const MovieDiscussionWidget({super.key, required this.mediaItem});

  @override
  State<MovieDiscussionWidget> createState() => _MovieDiscussionWidgetState();
}

class _MovieDiscussionWidgetState extends State<MovieDiscussionWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  String? _editingCommentId;
  String? _replyToCommentId;
  String? _replyToUserName;

  DatabaseReference get _commentsRef => FirebaseDatabase.instance.ref(
      'media_comments/${widget.mediaItem.mediaType}_${widget.mediaItem.id}/comments');

  User? get _user => FirebaseAuth.instance.currentUser;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditComment({String? parentId}) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _user == null) return;
    if (_editingCommentId != null) {
      await _commentsRef.child(_editingCommentId!).update({
        'text': text,
        'edited': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      setState(() {
        _editingCommentId = null;
        _commentController.clear();
      });
      return;
    }
    final newComment = Comment(
      id: '',
      userId: _user!.uid,
      userName: await _getProfileUsername(_user!.uid),
      userAvatarUrl: _user!.photoURL ?? '',
      text: text,
      timestamp: DateTime.now(),
      edited: false,
      parentId: parentId,
      likes: [],
    );
    await _commentsRef.push().set(newComment.toMap());
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
      _commentController.clear();
    });
  }

  Future<void> _deleteComment(String commentId, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[400],
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _commentsRef.child(commentId).remove();

      // Also delete any replies to this comment
      final snapshot =
          await _commentsRef.orderByChild('parentId').equalTo(commentId).get();

      if (snapshot.exists && snapshot.value is Map) {
        final replies = snapshot.value as Map;
        for (final replyId in replies.keys) {
          await _commentsRef.child(replyId.toString()).remove();
        }
      }
    }
  }

  Future<void> _toggleLike(Comment comment) async {
    if (_user == null) return;
    final likes = List<String>.from(comment.likes);
    if (likes.contains(_user!.uid)) {
      likes.remove(_user!.uid);
    } else {
      likes.add(_user!.uid);
    }
    await _commentsRef.child(comment.id).update({'likes': likes});
  }

  void _startEdit(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.text;
    });
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUserName = comment.userName;
      _commentController.text = '';
    });
  }

  void _cancelEditOrReply() {
    setState(() {
      _editingCommentId = null;
      _replyToCommentId = null;
      _replyToUserName = null;
      _commentController.clear();
    });
  }

  Stream<List<Comment>> _commentsStream() {
    return _commentsRef.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Comment>[];
      final map = Map<String, dynamic>.from(data as Map);
      return map.entries
          .map((e) => Comment.fromSnapshot(event.snapshot.child(e.key)))
          .toList();
    });
  }

  List<Comment> _getReplies(List<Comment> all, String parentId) {
    return all.where((c) => c.parentId == parentId).toList();
  }

  Future<String> _getProfileUsername(String uid) async {
    final ref = FirebaseDatabase.instance.ref('users/$uid');
    final snap = await ref.get();
    if (snap.exists &&
        snap.value is Map &&
        (snap.value as Map).containsKey('username')) {
      return (snap.value as Map)['username']?.toString() ?? 'Anonymous';
    }
    return 'Anonymous';
  }

  final Map<String, bool> _collapsedReplies = {};

  void _toggleRepliesVisibility(String commentId) {
    setState(() {
      if (_collapsedReplies[commentId] ?? false) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      _collapsedReplies[commentId] = !(_collapsedReplies[commentId] ?? false);
    });
  }

  Widget _buildAnimatedReplies(
      List<Comment> replies, List<Comment> allComments) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
      child: Column(
        children: [
          for (final reply in replies)
            _buildCommentTile(context, reply, allComments),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discussion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_user == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Sign in to comment.',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            StreamBuilder<List<Comment>>(
              stream: _commentsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                final topLevel =
                    comments.where((c) => c.parentId == null).toList();
                return Column(
                  children: [
                    for (final comment in topLevel)
                      _buildCommentTile(context, comment, comments),
                  ],
                );
              },
            ),
            const Divider(),
            if (_editingCommentId != null)
              Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Editing comment',
                      style: TextStyle(color: Colors.amber)),
                  const Spacer(),
                  TextButton(
                      onPressed: _cancelEditOrReply,
                      child: const Text('Cancel')),
                ],
              ),
            if (_replyToUserName != null)
              Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Replying to @$_replyToUserName',
                      style: TextStyle(color: Colors.blue)),
                  const Spacer(),
                  TextButton(
                      onPressed: _cancelEditOrReply,
                      child: const Text('Cancel')),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    enabled: _user != null,
                    decoration: InputDecoration(
                      hintText: _editingCommentId != null
                          ? 'Edit your comment...'
                          : _replyToUserName != null
                              ? 'Reply to @$_replyToUserName...'
                              : 'Add a comment...',
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _editingCommentId != null ? Icons.check : Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _user == null
                      ? null
                      : () => _addOrEditComment(parentId: _replyToCommentId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(
      BuildContext context, Comment comment, List<Comment> allComments) {
    final isOwner = _user?.uid == comment.userId;
    final replies = _getReplies(allComments, comment.id);
    final hasReplies = replies.isNotEmpty;
    // Default to collapsed if not set
    final isCollapsed = _collapsedReplies[comment.id] ?? true;
    final isReply = comment.parentId != null;

    // Compose display text for replies: @username (no spaces) + reply text
    String displayText = comment.text;
    if (isReply) {
      final parentComment = allComments.firstWhere(
        (c) => c.id == comment.parentId,
        orElse: () => comment,
      );
      final mention = '@${parentComment.userName.replaceAll(' ', '_')}';
      displayText = '$mention $displayText';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReply
                  ? Theme.of(context).cardColor.withOpacity(0.30)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: comment.userAvatarUrl.isNotEmpty
                          ? NetworkImage(comment.userAvatarUrl)
                          : null,
                      child: comment.userAvatarUrl.isEmpty
                          ? Icon(Icons.person,
                              color: Colors.grey[400], size: 24)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.90),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _getTimeAgo(comment.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOwner)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red[300],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style:
                                            TextStyle(color: Colors.red[300]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _startEdit(comment);
                                } else if (value == 'delete') {
                                  _deleteComment(comment.id, context);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionButton(
                      icon: comment.likes.contains(_user?.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: comment.likes.length.toString(),
                      textColor: comment.likes.contains(_user?.uid)
                          ? Colors.red[400]
                          : null,
                      onPressed: () => _toggleLike(comment),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      icon: Icons.reply,
                      label: 'Reply',
                      onPressed: () => _startReply(comment),
                    ),
                    if (hasReplies) ...[
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon:
                            isCollapsed ? Icons.expand_more : Icons.expand_less,
                        label:
                            '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                        onPressed: () => _toggleRepliesVisibility(comment.id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (hasReplies && !isCollapsed) ...[
            const SizedBox(height: 8),
            Column(
              children: [
                for (final reply in replies)
                  _buildCommentTile(context, reply, allComments),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;
  final Color? textColor;
  final double? fontSize;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.fontSize = 13,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(30, 24),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: textColor,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: (fontSize ?? 13) + 2),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? 13,
            ),
          ),
        ],
      ),
    );
  }
}
