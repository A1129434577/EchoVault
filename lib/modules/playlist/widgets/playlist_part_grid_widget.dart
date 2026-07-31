import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';

class PlaylistPartGridWidget extends StatelessWidget {
  final List<FileGroup> playlistList;
  const PlaylistPartGridWidget({
    super.key,
    required this.playlistList,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth-12*2)/7*3;
        double aspectRatio = 1;
        return SizedBox(
          height: itemWidth*aspectRatio+35,
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
              FileGroup fileGroup = playlistList[index];
              return _PlaylistHGridCell(fileGroup: fileGroup);
            },
          ),
        );
      },

    );
  }
}

class _PlaylistHGridCell extends StatelessWidget {
  final FileGroup fileGroup;
  const _PlaylistHGridCell({
    super.key,
    required this.fileGroup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        PlaylistDetailPageUtil.to(fileGroup: fileGroup);
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
                image: DecorationImage(image: Assets.other.albumPlaceholder.provider()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: NetworkImageWidget(
                url: fileGroup.thumbnail,
              ),
            ),
          ),
          Text(
            fileGroup.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }
}

