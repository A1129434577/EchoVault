import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/artist_detail_page.dart';
import 'package:echo_vault/modules/artist/widgets/favorite_artist_widget.dart';

class ArtistListCell extends StatelessWidget {
  final ArtistInfo artistInfo;
  final Widget? action;
  const ArtistListCell({
    super.key,
    required this.artistInfo,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        ArtistDetailPageUtil.to(artistInfo: artistInfo);
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        spacing: 16,
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
          Expanded(
            child: Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistInfo.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                if(artistInfo.desc.isNotEmpty)Text(
                  artistInfo.desc,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff141414).withAlpha((255*0.5).round())
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            child: action??FavoriteArtistWidget(artist: artistInfo),
          ),
        ],
      ),
    );
  }
}
