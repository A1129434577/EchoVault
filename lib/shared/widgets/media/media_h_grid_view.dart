import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/shared/widgets/media/media_cell.dart';

class MediaHGridView extends StatelessWidget {
  final List<FileInfo> fileList;
  final ValueChanged<FileInfo>? onCellTap;
  const MediaHGridView({super.key, required this.fileList, this.onCellTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (fileList.length > 3)
          ? (66 * 3 + 6 * 2)
          : (fileList.length > 2 ? 66 * 2 + 6 : 66),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              mainAxisExtent: constraints.maxWidth * 0.8,
              maxCrossAxisExtent: 66,
            ),
            itemCount: fileList.length,
            itemBuilder: (BuildContext ctx, int index) {
              FileInfo mediaEntry = fileList[index];
              return ValueListenableBuilder(
                valueListenable:
                    PlayerPlayback.instance.player.currentMediaInfo,
                builder:
                    (
                      BuildContext context,
                      FileInfo? currentMediaInfo,
                      Widget? child,
                    ) {
                      int activeIndex = -1;
                      if (currentMediaInfo?.fileId == mediaEntry.fileId) {
                        activeIndex = index;
                      }
                      if (currentMediaInfo != null &&
                          fileList.contains(currentMediaInfo)) {
                        activeIndex = fileList.indexOf(currentMediaInfo);
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color: index == activeIndex ? Color(0xffEFF6FE) : null,
                        child: GestureDetector(
                          onTap: () {
                            if (onCellTap == null) {
                              PlaybackNavigator.toPlay(
                                mediaQueue: fileList,
                                mediaEntry: mediaEntry,
                              );
                            } else {
                              onCellTap!.call(mediaEntry);
                            }
                          },
                          behavior: HitTestBehavior.translucent,
                          child: MediaCell(
                            mediaDetails: mediaEntry,
                            isGrid: true,
                          ),
                        ),
                      );
                    },
              );
            },
          );
        },
      ),
    );
  }
}
