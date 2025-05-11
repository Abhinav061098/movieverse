import 'package:flutter/material.dart';
import '../../../../core/widgets/media_card.dart';
import '../../viewmodels/movie_view_model.dart';
import '../../viewmodels/tv_show_view_model.dart';

class MediaSectionList extends StatelessWidget {
  final String title;
  final List<dynamic> mediaList;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final void Function(dynamic media)? onMediaTap;

  const MediaSectionList({
    Key? key,
    required this.title,
    required this.mediaList,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.onMediaTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mediaList.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 286,
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Positioned(
            top: 42,
            left: -7,
            right: 0,
            bottom: 0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: mediaList.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == mediaList.length) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                }

                final media = mediaList[index];
                return MediaCard(
                  media: media,
                  onTap: () => onMediaTap?.call(media),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: onLoadMore,
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
