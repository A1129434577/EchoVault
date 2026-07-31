import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/artist_detail_page.dart';

class ArtistPartGridWidget extends StatelessWidget {
  final List<ArtistInfo> artistList;
  const ArtistPartGridWidget({
    super.key,
    required this.artistList,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth-12*4)/9*2;
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
            itemCount: artistList.length,
            itemBuilder: (BuildContext ctx, int index) {
              ArtistInfo artistInfo = artistList[index];
              return _ArtistGridCell(artistInfo: artistInfo);
            },
          ),
        );
      },

    );
  }
}

class _ArtistGridCell extends StatelessWidget {
  final ArtistInfo artistInfo;
  const _ArtistGridCell({
    super.key,
    required this.artistInfo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        ArtistDetailPageUtil.to(artistInfo: artistInfo);
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: Assets.images.artist.profileAvatar.provider()),
              ),
              child: NetworkImageWidget(
                url: artistInfo.thumbnail,
              ),
            ),
          ),
          Text(
            artistInfo.name,
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