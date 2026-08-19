import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/shared/dialogs/queue_list_panel.dart';
import 'package:echo_vault/shared/dialogs/rating_dialog.dart';
import 'package:echo_vault/core/state/bookmark_performer_state.dart';
import 'package:echo_vault/core/state/bookmark_media_state.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/state/media_transfer_service.dart';
import 'package:echo_vault/features/performers/performer_detail_screen.dart';
import 'package:echo_vault/features/performers/widgets/bookmark_performer_view.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';
import 'package:echo_vault/core/networking/music_catalog_gateway.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';

class AdvertisingDisplayCoordinator {
  static bool audioTemporarilyMuted = false;

  static final DebounceUtil _displayThrottle = DebounceUtil();

  static Future<bool?> showScene({
    required AdScene scene,
    AdDetailScene? detailScene,
    bool verifyCd = true,
    dynamic params,
  }) async {
    return _displayThrottle<Future<bool?>>(
      Duration(milliseconds: 1500),
      () async {
        bool? showSuccessValueLocal = await AdHelper.showScene(
          scene: scene,
          detailScene: detailScene,
          verifyCd: verifyCd,
          params: params,
        );
        if (showSuccessValueLocal != true) {
          //搜索、下载、收藏或者播放的时候出现好评引导
          if (detailScene == AdvertisingDetailScene.searchResults ||
              detailScene == AdvertisingDetailScene.mediaDownload ||
              detailScene == AdvertisingDetailScene.savedCollection ||
              detailScene == AdvertisingDetailScene.playback) {
            DateTime nowLocal = DateTime.now();
            SharedPreferences sp = await SharedPreferences.getInstance();
            int? ratingPromptTimestamp = sp.getInt(UserPreferenceKeys.ratingPromptLastShown);
            if(ratingPromptTimestamp==null){
              ratingPromptTimestamp = DateTime.now().millisecondsSinceEpoch;
              await sp.setInt(UserPreferenceKeys.ratingPromptLastShown, ratingPromptTimestamp);
            }
            if (nowLocal
                    .difference(
                      DateTime.fromMillisecondsSinceEpoch(
                        ratingPromptTimestamp,
                      ),
                    )
                    .inHours >
                24) {
              int rateAlertShowCountLocal =
                  sp.getInt(
                    UserPreferenceKeys.ratingPromptCount,
                  ) ??
                  0;
              if (rateAlertShowCountLocal < 5) {
                RatingDialog.show();
                await sp.setInt(
                  UserPreferenceKeys.ratingPromptLastShown,
                  DateTime.now().millisecondsSinceEpoch,
                );
                rateAlertShowCountLocal++;
                await sp.setInt(
                  UserPreferenceKeys.ratingPromptCount,
                  rateAlertShowCountLocal,
                );
              }
            }
          }
        }
        return showSuccessValueLocal;
      },
    );
  }

  static void start() async {
    //前后台监听
    AppLifecycleObserver.lifecycleStream.listen((stateArg) {
      if (stateArg == AppLifecycleState.foreground) {
        showScene(
          scene: AdvertisingScene.appLaunch,
          detailScene: AdvertisingDetailScene.warmResume,
        );
      }
    });

    ///路由监听
    AppRouteObserver.observer.addListener(() {
      String? currentRouteNameLocal =
          AppRouteObserver.observer.currentRouteName;
      String? previousRouteNameLocal =
          AppRouteObserver.observer.previousRouteName;
      if ((currentRouteNameLocal == CollectionDetailScreenHelper.screenRoute ||
              currentRouteNameLocal ==
                  PerformerDetailScreenHelper.screenRoute) &&
          AppRouteObserver.observer.type == AppRouteChangeType.push) {
        showScene(
          scene: AdvertisingScene.fullScreen,
          detailScene: AdvertisingDetailScene.details,
        );
      }
      if (AppRouteObserver.observer.type == AppRouteChangeType.pop &&
          previousRouteNameLocal?.endsWith('Alert') != true &&
          previousRouteNameLocal?.endsWith('Sheet') != true &&
          previousRouteNameLocal != null) {
        showScene(
          scene: AdvertisingScene.fullScreen,
          detailScene: AdvertisingDetailScene.popup,
        );
      }
    });

    ///手动操作播放监听
    PlayerPlayback.instance.player.playStatusStream.listen((playStateInputArg) {
      if (playStateInputArg.isAuto == false &&
          playStateInputArg.state != PlayState.triggerSeek) {
        String? previousRouteNameLocal =
            AppRouteObserver.observer.previousRouteName;
        if (playStateInputArg.state == PlayState.playIndex &&
            previousRouteNameLocal != QueueListPanel.panelRoute) {
          showScene(
            scene: AdvertisingScene.fullScreen,
            detailScene: AdvertisingDetailScene.playbackStart,
          );
        } else {
          showScene(
            scene: AdvertisingScene.fullScreen,
            detailScene: AdvertisingDetailScene.playback,
          );
        }
      }
    });

    PlayerPlayback.instance.playModeInfo.addListener(() {
      if (PlayerPlayback.instance.playModeInfo.value.isAuto == false) {
        showScene(
          scene: AdvertisingScene.fullScreen,
          detailScene: AdvertisingDetailScene.playback,
        );
      }
    });

    ///网络请求监听
    NetworkManager.httpStatusStream.listen((httpStatusInputArg) {
      if (httpStatusInputArg.status == AppNetworkState.loading) {
        //搜索主页接口
        if (httpStatusInputArg.url ==
                MusicCatalogGateway.musicApiRoot +
                    MusicCatalogEndpoints.catalogSearch ||
            httpStatusInputArg.url ==
                MusicCatalogGateway.videoApiRoot +
                    MusicCatalogEndpoints.videoSearch) {
          showScene(
            scene: AdvertisingScene.fullScreen,
            detailScene: AdvertisingDetailScene.searchResults,
          );
        }
      }
    });

    ///点击收藏监听
    BookmarkMediaState.favoriteStream.listen((entry) {
      showScene(
        scene: AdvertisingScene.fullScreen,
        detailScene: AdvertisingDetailScene.savedCollection,
      );
    });
    BookmarkPerformerState.favoriteStream.listen((entry) {
      showScene(
        scene: AdvertisingScene.fullScreen,
        detailScene: AdvertisingDetailScene.savedCollection,
      );
    });
    BookmarkCollectionState.favoriteStream.listen((entry) {
      if (entry.id?.startsWith(NewCollectionDialog.generatedCollectionPrefix) ==
          false) {
        showScene(
          scene: AdvertisingScene.fullScreen,
          detailScene: AdvertisingDetailScene.savedCollection,
        );
      }
    });

    ///点击下载监听
    MediaTransferService.downloadStartStream.listen((
      downloadStartInfoInputArg,
    ) {
      if (downloadStartInfoInputArg.isClick) {
        showScene(
          scene: AdvertisingScene.fullScreen,
          detailScene: AdvertisingDetailScene.mediaDownload,
        );
      }
    });

    ///播放音乐时广告静音
    PlayerPlayback.instance.player.isLoading.addListener(() async {
      if (PlayerPlayback.instance.player.isLoading.value == true) {
        if (audioTemporarilyMuted == false) {
          audioTemporarilyMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      }
    });
    PlayerPlayback.instance.player.isPlaying.addListener(() async {
      if (PlayerPlayback.instance.player.isPlaying.value == true) {
        if (audioTemporarilyMuted == false) {
          audioTemporarilyMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      } else {
        await Future.delayed(Duration(seconds: 2));
        if (PlayerPlayback.instance.player.isLoading.value == false &&
            PlayerPlayback.instance.player.isPlaying.value == false) {
          audioTemporarilyMuted = false;
          MobileAds.instance.setAppMuted(false);
        }
      }
    });
  }
}
