import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/playback/controllers/playback_coordinator.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';
import 'package:echo_vault/features/playback/widgets/playback_slider.dart';

typedef PlaybackBarBuilder<T> =
    Widget Function(BuildContext buildContext, double barHeightArg);

class PlaybackBar extends StatefulWidget {
  final PlaybackBarBuilder builder;
  const PlaybackBar({super.key, required this.builder});

  @override
  State<PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<PlaybackBar> {
  final PlaybackCoordinator controller = PlaybackCoordinator();

  @override
  Widget build(BuildContext context) {
    double contentHeightLocal = 58;
    double paddingBottomLocal = max(MediaQuery.of(context).padding.bottom, 8);
    double barHeightLocal = contentHeightLocal + paddingBottomLocal;

    Widget encodedContent = widget.builder(
      context,
      barHeightLocal + paddingBottomLocal,
    );

    return ValueListenableBuilder(
      valueListenable: PlayerPlayback.instance.showPlayFileList,
      builder: (BuildContext context, List<FileInfo> showPlayFileList, Widget? child) {
        double newBarHeightLocal = barHeightLocal;
        if (showPlayFileList.isEmpty) {
          newBarHeightLocal = 0;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            newBarHeightLocal != barHeightLocal
                ? widget.builder(context, newBarHeightLocal)
                : encodedContent,
            if (showPlayFileList.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: paddingBottomLocal,
                  ),
                  child: SizedBox(
                    height: contentHeightLocal,
                    child: Stack(
                      children: [
                        ValueListenableBuilder(
                          valueListenable:
                              PlayerPlayback.instance.player.currentMediaInfo,
                          builder:
                              (
                                BuildContext context,
                                FileInfo? currentMediaInfo,
                                Widget? child,
                              ) {
                                currentMediaInfo ??= showPlayFileList.first;
                                return GestureDetector(
                                  onTap: () {
                                    PlaybackNavigator.toPlay();
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
                                            defaultView: Assets
                                                .images
                                                .media
                                                .audioNote
                                                .image(),
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
                                          valueListenable: PlayerPlayback
                                              .instance
                                              .player
                                              .isLoading,
                                          builder:
                                              (
                                                BuildContext context,
                                                bool isLoading,
                                                Widget? child,
                                              ) {
                                                return isLoading
                                                    ? ProgressView()
                                                    : ValueListenableBuilder(
                                                        valueListenable:
                                                            PlayerPlayback
                                                                .instance
                                                                .player
                                                                .isPlaying,
                                                        builder:
                                                            (
                                                              BuildContext
                                                              context,
                                                              bool isPlaying,
                                                              Widget? child,
                                                            ) {
                                                              return CupertinoButton(
                                                                onPressed: () {
                                                                  PlayerPlayback
                                                                      .instance
                                                                      .player
                                                                      .playOrPause(
                                                                        isAuto:
                                                                            false,
                                                                      );
                                                                },
                                                                sizeStyle:
                                                                    CupertinoButtonSize
                                                                        .small,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                child:
                                                                    (isPlaying
                                                                            ? Assets.images.player.miniPause
                                                                            : Assets.images.player.miniPlay)
                                                                        .image(
                                                                          width:
                                                                              32,
                                                                        ),
                                                              );
                                                            },
                                                      );
                                              },
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: CupertinoButton(
                                            onPressed: () {
                                              if (PlayerPlayback.instance.player
                                                  .hasNext()) {
                                                PlayerPlayback.instance.player
                                                    .playNext(isAuto: false);
                                              }
                                            },
                                            sizeStyle:
                                                CupertinoButtonSize.small,
                                            padding: EdgeInsets.zero,
                                            child:
                                                (PlayerPlayback.instance.player
                                                            .hasNext()
                                                        ? Assets
                                                              .images
                                                              .player
                                                              .miniNext
                                                        : Assets
                                                              .images
                                                              .player
                                                              .miniNextDisabled)
                                                    .image(),
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
                              valueListenable: PlayerPlayback
                                  .instance
                                  .player
                                  .currentMediaDuration,
                              builder:
                                  (
                                    BuildContext context,
                                    Duration? duration,
                                    Widget? child,
                                  ) {
                                    return ValueListenableBuilder(
                                      valueListenable: PlayerPlayback
                                          .instance
                                          .player
                                          .currentMediaBufferedPosition,
                                      builder:
                                          (
                                            BuildContext context,
                                            Duration? bufferedPosition,
                                            Widget? child,
                                          ) {
                                            return ValueListenableBuilder(
                                              valueListenable: PlayerPlayback
                                                  .instance
                                                  .player
                                                  .currentMediaPosition,
                                              builder:
                                                  (
                                                    BuildContext context,
                                                    Duration? position,
                                                    Widget? child,
                                                  ) {
                                                    return PlaybackSlider(
                                                      trackHeight: 4,
                                                      thumbSize: Size(0, 0),
                                                      duration: duration,
                                                      position: position,
                                                      buffered:
                                                          bufferedPosition,
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
