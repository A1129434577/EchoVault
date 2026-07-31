import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/player/controllers/play_controller.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/widgets/loading_widget.dart';
import 'package:echo_vault/modules/player/widgets/play_slider.dart';

typedef PlayBarContentBuilder<T> = Widget Function(BuildContext context, double barHeight);

class PlayBar extends StatefulWidget {
  final PlayBarContentBuilder builder;
  const PlayBar({
    super.key,
    required this.builder,
  });

  @override
  State<PlayBar> createState() => _PlayBarState();
}

class _PlayBarState extends State<PlayBar> {
  final PlayController controller = PlayController();

  @override
  Widget build(BuildContext context) {
    double contentHeight = 58;
    double paddingBottom = max(MediaQuery.of(context).padding.bottom, 8);
    double barHeight = contentHeight+paddingBottom;

    Widget content = widget.builder(context, barHeight+paddingBottom);

    return ValueListenableBuilder(
      valueListenable: PlayerPlayback.instance.showPlayFileList,
      builder: (BuildContext context, List<FileInfo> showPlayFileList, Widget? child) {
        double newBarHeight = barHeight;
        if(showPlayFileList.isEmpty){
          newBarHeight = 0;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            newBarHeight!=barHeight?widget.builder(context, newBarHeight):content,
            if(showPlayFileList.isNotEmpty)Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: paddingBottom),
                child: SizedBox(
                  height: contentHeight,
                  child: Stack(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: PlayerPlayback.instance.player.currentMediaInfo,
                        builder: (BuildContext context, FileInfo? currentMediaInfo, Widget? child) {
                          currentMediaInfo ??= showPlayFileList.first;
                          return GestureDetector(
                            onTap: (){
                              PlayHelper.toPlay();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xffF3F8FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: NetworkImageWidget(
                                      url: currentMediaInfo.thumbnail,
                                      radius: 2,
                                      defaultView: Assets.audioNote.image(),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      currentMediaInfo.displayName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: PlayerPlayback.instance.player.isLoading,
                                    builder: (BuildContext context, bool isLoading, Widget? child) {
                                      return isLoading?
                                      LoadingWidget():
                                      ValueListenableBuilder(
                                        valueListenable: PlayerPlayback.instance.player.isPlaying,
                                        builder: (BuildContext context, bool isPlaying, Widget? child) {
                                          return CupertinoButton(
                                            onPressed: (){
                                              PlayerPlayback.instance.player.playOrPause(isAuto: false);
                                            },
                                            sizeStyle: CupertinoButtonSize.small,
                                            padding: EdgeInsets.zero,
                                            child: (isPlaying
                                              ? Assets.other.miniPause
                                              : Assets.other.miniPlay).image(
                                              width: 32,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: CupertinoButton(
                                      onPressed: (){
                                        if(PlayerPlayback.instance.player.hasNext()){
                                          PlayerPlayback.instance.player.playNext(isAuto: false);
                                        }
                                      },
                                      sizeStyle: CupertinoButtonSize.small,
                                      padding: EdgeInsets.zero,
                                      child: (PlayerPlayback.instance.player.hasNext()
                                        ? Assets.other.miniNext
                                        : Assets.other.miniNextDisabled).image(
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: ValueListenableBuilder(
                            valueListenable: PlayerPlayback.instance.player.currentMediaDuration,
                            builder: (BuildContext context, Duration? duration,
                                Widget? child) {
                              return ValueListenableBuilder(
                                valueListenable: PlayerPlayback.instance.player.currentMediaBufferedPosition,
                                builder: (BuildContext context, Duration? bufferedPosition, Widget? child) {
                                  return ValueListenableBuilder(
                                    valueListenable: PlayerPlayback.instance.player.currentMediaPosition,
                                    builder: (BuildContext context, Duration? position,
                                        Widget? child) {
                                      return PlaySlider(
                                        trackHeight: 4,
                                        thumbSize: Size(0, 0),
                                        duration: duration,
                                        position: position,
                                        buffered: bufferedPosition,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
