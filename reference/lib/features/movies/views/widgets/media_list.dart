import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/media_card.dart';
import '../../models/media_item.dart';
import '../../viewmodels/media_list_viewmodel.dart';

class MediaList extends StatelessWidget {
  final String title;
  final List<MediaItem> items;

  const MediaList({super.key, required this.title, required this.items});

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
                  onTap: () {
                    context.read<MediaListViewModel>().navigateToDetails(
                          context,
                          items[index].item,
                        );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
