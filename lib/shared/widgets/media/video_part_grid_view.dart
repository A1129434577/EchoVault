import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/core/state/bookmark_media_state.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';

class VideoPartGridView extends StatelessWidget {
  final List<FileInfo> fileList;
  const VideoPartGridView({super.key, required this.fileList});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidthLocal = (constraints.maxWidth - 12) / 4 * 3;
        double aspectRatioLocal = 248 / 140;
        return SizedBox(
          height: itemWidthLocal / aspectRatioLocal + 35,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 12,
              mainAxisExtent: itemWidthLocal,
              crossAxisCount: 1,
            ),
            itemCount: fileList.length,
            itemBuilder: (BuildContext ctx, int index) {
              FileInfo mediaEntry = fileList[index];
              return GestureDetector(
                onTap: () {
                  PlaybackNavigator.toPlay(
                    mediaQueue: fileList,
                    mediaEntry: mediaEntry,
                  );
                },
                behavior: HitTestBehavior.translucent,
                child: _VideoGridCell(mediaDetails: mediaEntry),
              );
            },
          ),
        );
      },
    );
  }
}

class _VideoGridCell extends StatelessWidget {
  final FileInfo mediaDetails;
  const _VideoGridCell({super.key, required this.mediaDetails});

  @override
  Widget build(BuildContext context) {
    BookmarkMediaState favoriteFileControllerLocal = BookmarkMediaState(
      mediaEntry: mediaDetails,
    );
    TransferMediaState downloadControllerLocal = TransferMediaState();
    downloadControllerLocal.fileInfoNotifier.value = mediaDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 248 / 140,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffE8EDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: NetworkImageWidget(url: mediaDetails.thumbnail),
              ),
              Center(child: Assets.images.media.overlayPlay.image(width: 38)),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: favoriteFileControllerLocal.notifier,
          builder: (BuildContext context, FileInfo? value, Widget? child) {
            return ValueListenableBuilder(
              valueListenable: favoriteFileControllerLocal.notifier,
              builder: (BuildContext context, FileInfo? value, Widget? child) {
                return Text(
                  mediaDetails.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                );
              },
            );
          },
        ),
        if (mediaDetails.artist != null)
          Text(
            mediaDetails.artist!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Color(0xff595959)),
          ),
      ],
    );
  }
}
