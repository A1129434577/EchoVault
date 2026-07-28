import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/alerts/add_to_playlist_sheet.dart';
import 'package:echo_vault/alerts/file_actions_sheet.dart';
import 'package:echo_vault/alerts/playing_list_sheet.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/player/controllers/player_page_controller.dart';
import 'package:echo_vault/modules/player/widgets/save_guide_widget.dart';
import 'package:echo_vault/widgets/file/favorite_file_widget.dart';
import 'package:echo_vault/widgets/loading_widget.dart';
import 'package:echo_vault/modules/player/widgets/play_slider.dart';
import 'package:echo_vault/widgets/file/save_file_widget.dart';


class PlayHelper {
  static String routeName = '/$_PlayerPage';

  static toPlay({List<FileInfo>? fileList, FileInfo? fileInfo, PlayerPlayMode? playMode}){
    if(fileList?.isNotEmpty == true) {
      fileInfo ??= fileList!.first;

      if(playMode != null) {
        PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: playMode);
      }
      PlayerPlayback.instance.startPlayList(
        fileList!,
        playIndex: fileList.indexOf(fileInfo),
      );
    }
    showModalBottomSheet(
      context: Get.context!,
      barrierColor: Colors.white,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(name: PlayHelper.routeName, arguments: fileInfo),
      builder: (context){
        return _PlayerPage(fileInfo: fileInfo);
      },
    );
  }
}

class _PlayerPage extends StatefulWidget {
  final FileInfo? fileInfo;
  const _PlayerPage({
    super.key,
    this.fileInfo,
  });

  @override
  State<_PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<_PlayerPage> with SingleTickerProviderStateMixin {
  late final PlayerPageController _pageController = PlayerPageController(fileInfo: widget.fileInfo);
  final ValueNotifier<Duration?> _dragPosition = ValueNotifier(null);
  final GlobalKey _saveButtonKey = GlobalKey();
  late FileInfo? _lastNativeAdMedia = _pageController.player.currentMediaInfo.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp){
      Future.delayed(Duration(milliseconds: 500),(){
        SaveGuideWidget.show(targetKey: _saveButtonKey, fileInfo: _pageController.player.currentMediaInfo.value);
      });
    });
    _pageController.queryRecommendList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(Assets.otherPlayBg), fit: BoxFit.fill),
      ),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(Get.context!).padding.top,
          bottom: max(MediaQuery.of(Get.context!).padding.bottom+20, 20),
        ),
        child: Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Image.asset(Assets.otherPlayBack, height: 24),
              ),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: _pageController.player.currentMediaInfo,
                builder: (BuildContext context, FileInfo? currentMediaInfo, Widget? child) {
                  if(currentMediaInfo == null){
                    return SizedBox();
                  }
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: CupertinoButton(
                      onPressed: (){
                        FileActionsSheet.show(fileInfo: currentMediaInfo);
                      },
                      sizeStyle: CupertinoButtonSize.small,
                      padding: EdgeInsets.zero,
                      child: Image.asset(Assets.otherLMore, width: 24,),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ValueListenableBuilder(
            valueListenable: _pageController.player.currentMediaInfo,
            builder: (BuildContext context, FileInfo? currentMediaInfo, Widget? child) {
              if(currentMediaInfo?.fileId != _lastNativeAdMedia?.fileId){
                AdHelper.loadSceneAdIfNull(scene: AdsManagerScene.playNative, detailScene: AdsManagerDetailScene.play);
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
                              builder: (BuildContext context, AdInfo? playNatoAd, Widget? child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _mediaView(currentMediaInfo),
                                    if(playNatoAd!=null)Container(
                                      padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                                      alignment: Alignment.center,
                                      child: AspectRatio(
                                        aspectRatio: 300/250,
                                        child: NativePartAdView(
                                          adInfo: playNatoAd,
                                          onCloseButtonClick: (){
                                            _lastNativeAdMedia = _pageController.player.currentMediaInfo.value;
                                            _pageController.playNatoAd.value = null;
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

  Widget _mediaView(FileInfo? currentMediaInfo){
    return ValueListenableBuilder(
      valueListenable: _pageController.player.playerLoadInfo,
      builder: (BuildContext context, PlayerLoadInfo? playLoadInfo, Widget? child) {
        VideoPlayerController? playerController = playLoadInfo?.playerController;
        if (playerController != null) {
          double aspectRatio = playerController.value.aspectRatio;
          return Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: (aspectRatio==1)?24:0),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                children: [
                  NetworkImageWidget(
                    radius: 15,
                    url: currentMediaInfo?.thumbnail??'',
                    defaultView: Image.asset(Assets.assetsMusicIcon),
                  ),
                  VideoPlayer(playerController)
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
              url: currentMediaInfo?.thumbnail??'',
              defaultView: Image.asset(Assets.assetsMusicIcon),
            ),
          ),
        );
      },
    );
  }

  Widget _notMediaViews(FileInfo? currentMediaInfo){
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 50),
          _otherActions(currentMediaInfo),
          SizedBox(height: 30),
          _progressView(),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _positionText(),
              _durationText(),
            ],
          ),
          SizedBox(height: 30),
          _playActions(currentMediaInfo),
        ],
      ),
    );
  }

  Widget _nameText(FileInfo? currentMediaInfo){
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsetsGeometry.symmetric(horizontal: 24),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(currentMediaInfo!=null)
            Text(
              currentMediaInfo.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          if(currentMediaInfo?.artist!=null)
            Text(
              currentMediaInfo!.artist!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _otherActions(FileInfo? currentMediaInfo){
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            onPressed: (){
              if(currentMediaInfo != null){
                AddToPlaylistSheet.show(fileInfo: currentMediaInfo);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Image.asset(Assets.otherAddToPlaylist),
          ),
          FavoriteFileWidget(fileInfo: currentMediaInfo),
          SaveFileWidget(
            key: _saveButtonKey,
            fileInfo: currentMediaInfo,
          ),
          CupertinoButton(
            onPressed: (){
              PlayingListSheet.show();
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Image.asset(Assets.otherPlaylist),
          ),
        ],
      ),
    );
  }

  Widget _progressView() {
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaDuration,
      builder: (BuildContext context, Duration? currentDuration,
          Widget? child) {
        return ValueListenableBuilder(
          valueListenable: _pageController.player.currentMediaBufferedPosition,
          builder: (BuildContext context,
              Duration? currentBufferedPosition, Widget? child) {
            return ValueListenableBuilder(
              valueListenable: _pageController.player.currentMediaPosition,
              builder: (BuildContext context, Duration? currentPosition,
                  Widget? child) {
                return ValueListenableBuilder(
                  valueListenable: _dragPosition,
                  builder: (BuildContext context, Duration? dragPosition, Widget? child) {
                    return PlaySlider(
                      thumbSize: Size(10, 10),
                      duration: currentDuration,
                      position: dragPosition??currentPosition,
                      buffered: currentBufferedPosition,
                      onChanged: (value){
                        _dragPosition.value = Duration(seconds: value.toInt());
                      },
                      onChangeEnd: (value) async {
                        await _pageController.player.seek(Duration(seconds: value.toInt()));
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

  Widget _positionText(){
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaPosition,
      builder: (BuildContext context, Duration? currentPosition,
          Widget? child) {
        return ValueListenableBuilder(
          valueListenable: _dragPosition,
          builder: (BuildContext context, Duration? dragPosition, Widget? child) {
            return Text(
              currentPosition == null ?
              '00.00' :
              dragPosition!=null ?
              dragPosition.format(isSimple: true) :
              currentPosition.format(isSimple: true),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xff121212).withAlpha((255*0.6).round()),
              ),
            );
          },
        );
      },
    );
  }

  Widget _durationText(){
    return ValueListenableBuilder(
      valueListenable: _pageController.player.currentMediaDuration,
      builder: (BuildContext context, Duration? currentDuration,
          Widget? child) {
        return Text(
          currentDuration == null ?
          '00.00' :
          currentDuration.format(isSimple: true),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Color(0xff121212).withAlpha((255*0.6).round()),
          ),
        );
      },
    );
  }

  Widget _playActions(FileInfo? currentMediaInfo){
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder(
            valueListenable: PlayerPlayback.instance.playModeInfo,
            builder: (BuildContext context, PlayerPlayModeInfo playModeInfo, Widget? child) {
              return CupertinoButton(
                onPressed: (){
                  if(playModeInfo.mode == PlayerPlayMode.shuffle) {
                    PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: PlayerPlayMode.loop, isAuto: false);
                  }else if(playModeInfo.mode == PlayerPlayMode.loop) {
                    PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: PlayerPlayMode.loopOne, isAuto: false);
                  }else if(playModeInfo.mode == PlayerPlayMode.loopOne) {
                    PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: PlayerPlayMode.loop, isAuto: false);
                  }
                },
                sizeStyle: CupertinoButtonSize.small,
                padding: EdgeInsets.zero,
                child: Image.asset(playModeInfo.mode==PlayerPlayMode.loopOne?Assets.otherLoopOne:Assets.otherLoop, width: 32),
              );
            },
          ),
          CupertinoButton(
            onPressed: (){
              if(_pageController.player.hasPrevious()){
                _pageController.player.playPrevious(isAuto: false);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Image.asset(_pageController.player.hasPrevious()?Assets.otherPrevious:Assets.otherPreviousNo, width: 32),
          ),
          SizedBox(
            width: 64,
            child: ValueListenableBuilder(
              valueListenable: _pageController.player.isLoading,
              builder: (BuildContext context, bool isLoading, Widget? child) {
                return isLoading?
                LoadingWidget():
                ValueListenableBuilder(
                  valueListenable: _pageController.player.isPlaying,
                  builder: (BuildContext context, bool isPlaying, Widget? child) {
                    return CupertinoButton(
                      onPressed: (){
                        _pageController.player.playOrPause(isAuto: false);
                      },
                      sizeStyle: CupertinoButtonSize.small,
                      padding: EdgeInsets.zero,
                      child: Image.asset(isPlaying?Assets.otherPause:Assets.otherPlay, width: 64),
                    );
                  },
                );
              },
            ),
          ),
          CupertinoButton(
            onPressed: (){
              if(_pageController.player.hasNext()){
                _pageController.player.playNext(isAuto: false);
              }
            },
            sizeStyle: CupertinoButtonSize.small,
            padding: EdgeInsets.zero,
            child: Image.asset(_pageController.player.hasNext()?Assets.otherNext:Assets.otherNextNo, width: 32),
          ),
          ValueListenableBuilder(
            valueListenable: PlayerPlayback.instance.playModeInfo,
            builder: (BuildContext context, PlayerPlayModeInfo playModeInfo, Widget? child) {
              return CupertinoButton(
                onPressed: (){
                  PlayerPlayback.instance.playModeInfo.value = PlayerPlayModeInfo(mode: PlayerPlayMode.shuffle, isAuto: false);
                },
                sizeStyle: CupertinoButtonSize.small,
                padding: EdgeInsets.zero,
                child: Image.asset(playModeInfo.mode==PlayerPlayMode.shuffle?Assets.otherShuffleS:Assets.otherShuffle, width: 32),
              );
            },
          ),
        ],
      ),
    );
  }
}
