import 'package:flutter/material.dart';
import '../../../../core/widgets/media_card.dart';
import '../../models/media_item.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final void Function(MediaItem media) onTap;

  const MediaGrid({Key? key, required this.items, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final media = items[index].item;
        return MediaCard(
          media: media,
          onTap: () => onTap(media),
        );
      },
    );
  }
}
