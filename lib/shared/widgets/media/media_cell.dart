import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/dialogs/media_options_panel.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/shared/widgets/media/bookmark_media_view.dart';
import 'package:echo_vault/shared/widgets/media/save_media_view.dart';

class MediaCell extends StatelessWidget {
  final FileInfo mediaDetails;
  final bool isGrid;
  final bool isVideo;
  const MediaCell({
    super.key,
    required this.mediaDetails,
    this.isGrid = false,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    BookmarkMediaState favoriteFileController = BookmarkMediaState(
      mediaDetails: mediaDetails,
    );
    return Row(
      children: [
        AspectRatio(
          aspectRatio: isVideo ? 98 / 56 : 1,
          child: NetworkImageWidget(
            url: mediaDetails.thumbnail,
            radius: 6,
            defaultView: isVideo
                ? Container(color: Color(0xffE8EDF4))
                : Assets.images.media.audioTrack.image(),
          ),
        ),
        SizedBox(width: isGrid ? 10 : 12),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: favoriteFileController.notifier,
            builder: (BuildContext context, FileInfo? value, Widget? child) {
              return Column(
                spacing: isGrid ? 4 : 6,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaDetails.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (value?.isFavorite == 1 ||
                      mediaDetails.artist?.isNotEmpty == true)
                    Row(
                      spacing: 2,
                      children: [
                        if (value?.isFavorite == 1)
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: BookmarkMediaView(
                              mediaDetails: mediaDetails,
                              controller: favoriteFileController,
                            ),
                          ),
                        if (mediaDetails.artist?.isNotEmpty == true)
                          Flexible(
                            child: Text(
                              mediaDetails.artist!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(
                                  0xff141414,
                                ).withAlpha((255 * 0.5).round()),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 12),
        SizedBox(height: 24, child: SaveMediaView(mediaDetails: mediaDetails)),
        SizedBox(width: isGrid ? 2 : 8),
        CupertinoButton(
          onPressed: () {
            MediaOptionsPanel.show(mediaDetails: mediaDetails);
          },
          sizeStyle: CupertinoButtonSize.small,
          padding: EdgeInsets.zero,
          child: Assets.images.collection.listOptions.image(
            height: 24,
          ),
        ),
      ],
    );
  }
}
