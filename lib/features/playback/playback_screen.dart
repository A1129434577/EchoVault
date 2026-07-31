import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/append_to_collection_panel.dart';
import 'package:echo_vault/shared/dialogs/media_options_panel.dart';
import 'package:echo_vault/shared/dialogs/queue_list_panel.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/playback/controllers/playback_screen_state.dart';
import 'package:echo_vault/features/playback/widgets/save_guide_view.dart';
import 'package:echo_vault/shared/widgets/media/bookmark_media_view.dart';
import 'package:echo_vault/shared/widgets/progress_view.dart';
import 'package:echo_vault/features/playback/widgets/playback_slider.dart';
import 'package:echo_vault/shared/widgets/media/save_media_view.dart';

class PlaybackNavigator {
  static String routeName = '/$_PlaybackScreen';

  static toPlay({
    List<FileInfo>? mediaQueue,
    FileInfo? mediaEntry,
    PlayerPlayMode? playModeArg,
  }) {
    if (mediaQueue?.isNotEmpty == true) {
      mediaEntry ??= mediaQueue!.first;

      if (playModeArg != null) {
        PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(
          mode: playModeArg,
        );
      }
      PlayerPlayback.instance.startPlayList(
        mediaQueue!,
        playIndex: mediaQueue.indexOf(mediaEntry),
      );
    }
    showModalBottomSheet(
      context: Get.context!,
      barrierColor: Colors.white,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(
        name: PlaybackNavigator.routeName,
        arguments: mediaEntry,
      ),
      builder: (buildContext) {
        return _PlaybackScreen(mediaDetails: mediaEntry);
      },
    );
  }
}

class _PlaybackScreen extends StatefulWidget {
  final FileInfo? mediaDetails;
  const _PlaybackScreen({super.key, this.mediaDetails});

  @override
  State<_PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<_PlaybackScreen>
    with SingleTickerProviderStateMixin {
  late final PlaybackScreenState _pageController = PlaybackScreenState(
    mediaDetails: widget.mediaDetails,
  );
  final ValueNotifier<Duration?> _dragPosition = ValueNotifier(null);
  final GlobalKey _saveButtonKey = GlobalKey();
  late FileInfo? _lastNativeAdMedia =
      _pageController.player.currentMediaInfo.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(Duration(milliseconds: 500), () {
        SaveGuideView.show(
          targetKeyArg: _saveButtonKey,
          mediaEntry: _pageController.player.currentMediaInfo.value,
        );
      });
    });
    _pageController.queryRecommendList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.player.playerBackdrop.provider(),
          fit: BoxFit.fill,
        ),
      ),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(Get.context!).padding.top,
          bottom: max(MediaQuery.of(Get.context!).padding.bottom + 20, 20),
        ),
        child: Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Assets.images.player.playerBack.image(height: 24),
              ),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: _pageController.player.currentMediaInfo,
                builder:
                    (
                      BuildContext context,
                      FileInfo? currentMediaInfo,
                      Widget? child,
                    ) {
                      if (currentMediaInfo == null) {
                        return SizedBox();
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: CupertinoButton(
                          onPressed: () {
                            MediaOptionsPanel.show(
                              mediaEntry: currentMediaInfo,
                            );
                          },
                          sizeStyle: CupertinoButtonSize.small,
                          padding: EdgeInsets.zero,
                          child: Assets.images.collection.listOptions.image(
                            width: 24,
                          ),
                        ),
                      );
                    },
              ),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: _pageController.player.currentMediaInfo,
            builder:
                (
                  BuildContext context,
                  FileInfo? currentMediaInfo,
                  Widget? child,
                ) {
                  if (currentMediaInfo?.fileId != _lastNativeAdMedia?.fileId) {
                    AdHelper.loadSceneAdIfNull(
                      scene: AdvertisingScene.playNative,
                      detailScene: AdvertisingDetailScene.play,
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: ValueListenableBuilder(
                                  valueListenable: _pageController.playNatoAd,
                                  builder:
                                      (
                                        BuildContext context,
                                        AdInfo? playNatoAd,
                                        Widget? child,
                                      ) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            _mediaView(currentMediaInfo),
                                            if (playNatoAd != null)
                                              Container(
                                                padding:
                                                    EdgeInsetsGeometry.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                alignment: Alignment.center,
                                                child: AspectRatio(
                                                  aspectRatio: 300 / 250,
                                                  child: NativePartAdView(
                                                    adInfo: playNatoAd,
                                                    onCloseButtonClick: () {
                                                      _lastNativeAdMedia =
                                                          _pageController
                                                              .player
                                                              .currentMediaInfo
                                                              .value;
                                                      _pageController
                                                              .playNatoAd
                                                              .value =
                                                          null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                ),
                              ),
                            ),
                            _nameText(currentMediaInfo),
                          ],
                        ),
                      ),
                      _notMediaViews(currentMediaInfo),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _durationText() {
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaDuration,
      builder:
          (
            BuildContext buildContext,
            Duration? currentDurationArg,
            Widget? nestedEntry,
          ) {
            return Text(
              currentDurationArg == null
                  ? '00.00'
                  : currentDurationArg.format(isSimple: true),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xff121212).withAlpha((255 * 0.6).round()),
              ),
            );
          },
    );
  }

  Widget _mediaView(FileInfo? currentMediaInfoArg) {
    return ValueListenableBuilder(
      valueListenable: _pageController.player.playerLoadInfo,
      builder:
          (
            BuildContext buildContext,
            PlayerLoadInfo? playLoadInfoArg,
            Widget? nestedEntry,
          ) {
            VideoPlayerController? playerControllerLocal =
                playLoadInfoArg?.playerController;
            if (playerControllerLocal != null) {
              double aspectRatioLocal = playerControllerLocal.value.aspectRatio;
              return Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: (aspectRatioLocal == 1) ? 24 : 0,
                ),
                child: AspectRatio(
                  aspectRatio: aspectRatioLocal,
                  child: Stack(
                    children: [
                      NetworkImageWidget(
                        radius: 15,
                        url: currentMediaInfoArg?.thumbnail ?? '',
                        defaultView: Assets.images.media.audioNote.image(),
                      ),
                      VideoPlayer(playerControllerLocal),
                    ],
                  ),
                ),
              );
            }
            return Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 1,
                child: NetworkImageWidget(
                  radius: 15,
                  url: currentMediaInfoArg?.thumbnail ?? '',
                  defaultView: Assets.images.media.audioNote.image(),
                ),
              ),
            );
          },
    );
  }

  Widget _nameText(FileInfo? currentMediaInfoArg) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentMediaInfoArg != null)
            Text(
              currentMediaInfoArg.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 24),
            ),
          if (currentMediaInfoArg?.artist != null)
            Text(
              currentMediaInfoArg!.artist!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }

  Widget _notMediaViews(FileInfo? currentMediaInfoArg) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 50),
          _otherActions(currentMediaInfoArg),
          SizedBox(height: 30),
          _progressView(),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_positionText(), _durationText()],
          ),
          SizedBox(height: 30),
          _playActions(currentMediaInfoArg),
        ],
      ),
    );
  }

  Widget _otherActions(FileInfo? currentMediaInfoArg) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            onPressed: () {
              if (currentMediaInfoArg != null) {
                AppendToCollectionPanel.show(mediaEntry: currentMediaInfoArg);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Assets.images.collection.addPlaylistAction.image(),
          ),
          BookmarkMediaView(mediaDetails: currentMediaInfoArg),
          SaveMediaView(key: _saveButtonKey, mediaDetails: currentMediaInfoArg),
          CupertinoButton(
            onPressed: () {
              QueueListPanel.show();
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Assets.images.collection.playlistIcon.image(),
          ),
        ],
      ),
    );
  }

  Widget _playActions(FileInfo? currentMediaInfoArg) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder(
            valueListenable: PlayerPlayback.instance.playModeInfo,
            builder:
                (
                  BuildContext buildContext,
                  PlayerPlayModeInfo playModeInfoArg,
                  Widget? nestedEntry,
                ) {
                  return CupertinoButton(
                    onPressed: () {
                      if (playModeInfoArg.mode == PlayerPlayMode.shuffle) {
                        PlayerPlayback.instance.playModeInfo.value =
                            PlayerPlayModeInfo(
                              mode: PlayerPlayMode.loop,
                              isAuto: false,
                            );
                      } else if (playModeInfoArg.mode == PlayerPlayMode.loop) {
                        PlayerPlayback.instance.playModeInfo.value =
                            PlayerPlayModeInfo(
                              mode: PlayerPlayMode.loopOne,
                              isAuto: false,
                            );
                      } else if (playModeInfoArg.mode ==
                          PlayerPlayMode.loopOne) {
                        PlayerPlayback.instance.playModeInfo.value =
                            PlayerPlayModeInfo(
                              mode: PlayerPlayMode.loop,
                              isAuto: false,
                            );
                      }
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child:
                        (playModeInfoArg.mode == PlayerPlayMode.loopOne
                                ? Assets.images.player.repeatOne
                                : Assets.images.player.repeat)
                            .image(width: 32),
                  );
                },
          ),
          CupertinoButton(
            onPressed: () {
              if (_pageController.player.hasPrevious()) {
                _pageController.player.playPrevious(isAuto: false);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child:
                (_pageController.player.hasPrevious()
                        ? Assets.images.player.skipBack
                        : Assets.images.player.skipBackDisabled)
                    .image(width: 32),
          ),
          SizedBox(
            width: 64,
            child: ValueListenableBuilder(
              valueListenable: _pageController.player.isLoading,
              builder:
                  (
                    BuildContext buildContext,
                    bool isLoadingArg,
                    Widget? nestedEntry,
                  ) {
                    return isLoadingArg
                        ? ProgressView()
                        : ValueListenableBuilder(
                            valueListenable: _pageController.player.isPlaying,
                            builder:
                                (
                                  BuildContext buildContext,
                                  bool isPlayingArg,
                                  Widget? nestedEntry,
                                ) {
                                  return CupertinoButton(
                                    onPressed: () {
                                      _pageController.player.playOrPause(
                                        isAuto: false,
                                      );
                                    },
                                    sizeStyle: CupertinoButtonSize.small,
                                    padding: EdgeInsets.zero,
                                    child:
                                        (isPlayingArg
                                                ? Assets
                                                      .images
                                                      .player
                                                      .pauseControl
                                                : Assets
                                                      .images
                                                      .player
                                                      .playControl)
                                            .image(width: 64),
                                  );
                                },
                          );
                  },
            ),
          ),
          CupertinoButton(
            onPressed: () {
              if (_pageController.player.hasNext()) {
                _pageController.player.playNext(isAuto: false);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child:
                (_pageController.player.hasNext()
                        ? Assets.images.player.skipForward
                        : Assets.images.player.skipForwardDisabled)
                    .image(width: 32),
          ),
          ValueListenableBuilder(
            valueListenable: PlayerPlayback.instance.playModeInfo,
            builder:
                (
                  BuildContext buildContext,
                  PlayerPlayModeInfo playModeInfoArg,
                  Widget? nestedEntry,
                ) {
                  return CupertinoButton(
                    onPressed: () {
                      PlayerPlayback.instance.playModeInfo.value =
                          PlayerPlayModeInfo(
                            mode: PlayerPlayMode.shuffle,
                            isAuto: false,
                          );
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child:
                        (playModeInfoArg.mode == PlayerPlayMode.shuffle
                                ? Assets.images.player.shuffleActive
                                : Assets.images.player.shuffleControl)
                            .image(width: 32),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _positionText() {
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaPosition,
      builder:
          (
            BuildContext buildContext,
            Duration? currentPositionArg,
            Widget? nestedEntry,
          ) {
            return ValueListenableBuilder(
              valueListenable: _dragPosition,
              builder:
                  (
                    BuildContext buildContext,
                    Duration? dragPositionArg,
                    Widget? nestedEntry,
                  ) {
                    return Text(
                      currentPositionArg == null
                          ? '00.00'
                          : dragPositionArg != null
                          ? dragPositionArg.format(isSimple: true)
                          : currentPositionArg.format(isSimple: true),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff121212).withAlpha((255 * 0.6).round()),
                      ),
                    );
                  },
            );
          },
    );
  }

  Widget _progressView() {
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaDuration,
      builder:
          (
            BuildContext buildContext,
            Duration? currentDurationArg,
            Widget? nestedEntry,
          ) {
            return ValueListenableBuilder(
              valueListenable:
                  _pageController.player.currentMediaBufferedPosition,
              builder:
                  (
                    BuildContext buildContext,
                    Duration? currentBufferedPositionArg,
                    Widget? nestedEntry,
                  ) {
                    return ValueListenableBuilder(
                      valueListenable:
                          _pageController.player.currentMediaPosition,
                      builder:
                          (
                            BuildContext buildContext,
                            Duration? currentPositionArg,
                            Widget? nestedEntry,
                          ) {
                            return ValueListenableBuilder(
                              valueListenable: _dragPosition,
                              builder:
                                  (
                                    BuildContext buildContext,
                                    Duration? dragPositionArg,
                                    Widget? nestedEntry,
                                  ) {
                                    return PlaybackSlider(
                                      thumbSize: Size(10, 10),
                                      duration: currentDurationArg,
                                      position:
                                          dragPositionArg ?? currentPositionArg,
                                      buffered: currentBufferedPositionArg,
                                      onChanged: (currentValue) {
                                        _dragPosition.value = Duration(
                                          seconds: currentValue.toInt(),
                                        );
                                      },
                                      onChangeEnd: (currentValue) async {
                                        await _pageController.player.seek(
                                          Duration(
                                            seconds: currentValue.toInt(),
                                          ),
                                        );
                                        _dragPosition.value = null;
                                      },
                                    );
                                  },
                            );
                          },
                    );
                  },
            );
          },
    );
  }
}
