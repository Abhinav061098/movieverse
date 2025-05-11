import 'package:flutter/material.dart';
import '../../../../core/widgets/media_card.dart';
import '../../models/media_item.dart';

class MediaList extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final void Function(MediaItem) onTap;

  const MediaList({
    Key? key,
    required this.title,
    required this.items,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: MediaCard(
                  media: items[index].item,
                  onTap: () => onTap(items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
