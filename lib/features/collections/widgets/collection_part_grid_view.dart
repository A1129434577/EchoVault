import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';

class CollectionPartGridView extends StatelessWidget {
  final List<MediaCollection> playlistList;
  const CollectionPartGridView({super.key, required this.playlistList});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth - 12 * 2) / 7 * 3;
        double aspectRatio = 1;
        return SizedBox(
          height: itemWidth * aspectRatio + 35,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 12,
              mainAxisExtent: itemWidth,
              crossAxisCount: 1,
            ),
            itemCount: playlistList.length,
            itemBuilder: (BuildContext ctx, int index) {
              MediaCollection mediaCollection = playlistList[index];
              return _CollectionGridCell(mediaCollection: mediaCollection);
            },
          ),
        );
      },
    );
  }
}

class _CollectionGridCell extends StatelessWidget {
  final MediaCollection mediaCollection;
  const _CollectionGridCell({super.key, required this.mediaCollection});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CollectionDetailScreenHelper.to(mediaCollection: mediaCollection);
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: Assets.images.media.albumPlaceholder
                      .provider(),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: NetworkImageWidget(url: mediaCollection.thumbnail),
            ),
          ),
          Text(
            mediaCollection.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
