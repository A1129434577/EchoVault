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

class AdvertisingDisplayCoordinator {
  static final String _rateAlertShowCountKey = '_rateAlertShowCountKey';
  static final String _rateAlertLastShowTimeKey = '_rateAlertLastShowTimeKey';
  static int? rateAlertLastShowTime;
  static bool isMuted = false;

  static final DebounceUtil _debounce = DebounceUtil();

  static Future<bool?> showScene({
    required AdScene scene,
    AdDetailScene? detailScene,
    bool verifyCd = true,
    dynamic params,
  }) async {
    return _debounce<Future<bool?>>(Duration(milliseconds: 1500), () async {
      bool? showSuccess = await AdHelper.showScene(
        scene: scene,
        detailScene: detailScene,
        verifyCd: verifyCd,
        params: params,
      );
      if (showSuccess != true) {
        //搜索、下载、收藏或者播放的时候出现好评引导
        if (detailScene == AdvertisingDetailScene.search ||
            detailScene == AdvertisingDetailScene.download ||
            detailScene == AdvertisingDetailScene.collection ||
            detailScene == AdvertisingDetailScene.play) {
          DateTime now = DateTime.now();
          if (now
                  .difference(
                    DateTime.fromMillisecondsSinceEpoch(
                      appIsFirstInTimeForRate ?? 0,
                    ),
                  )
                  .inHours >
              24) {
            rateAlertLastShowTime = AdHelper.sharedPreferences.getInt(
              _rateAlertLastShowTimeKey,
            );
            if (now
                    .difference(
                      DateTime.fromMillisecondsSinceEpoch(
                        rateAlertLastShowTime ?? 0,
                      ),
                    )
                    .inHours >
                24) {
              int rateAlertShowCount =
                  AdHelper.sharedPreferences.getInt(_rateAlertShowCountKey) ??
                  0;
              if (rateAlertShowCount < 5) {
                RatingDialog.show();
                AdHelper.sharedPreferences.setInt(
                  _rateAlertLastShowTimeKey,
                  DateTime.now().millisecondsSinceEpoch,
                );
                rateAlertShowCount++;
                AdHelper.sharedPreferences.setInt(
                  _rateAlertShowCountKey,
                  rateAlertShowCount,
                );
              }
            }
          }
        }
      }
      return showSuccess;
    });
  }

  static final String _appIsFirstInTimeForRateKey =
      '_appIsFirstInTimeForRateKey';
  static int? appIsFirstInTimeForRate;

  static void start() async {
    appIsFirstInTimeForRate = AdHelper.sharedPreferences.getInt(
      _appIsFirstInTimeForRateKey,
    );
    if (appIsFirstInTimeForRate == null) {
      AdHelper.sharedPreferences.setInt(
        _appIsFirstInTimeForRateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    //前后台监听
    AppLifecycleObserver.lifecycleStream.listen((state) {
      if (state == AppLifecycleState.foreground) {
        showScene(
          scene: AdvertisingScene.open,
          detailScene: AdvertisingDetailScene.hotOpen,
        );
      }
    });

    ///路由监听
    AppRouteObserver.observer.addListener(() {
      String? currentRouteName = AppRouteObserver.observer.currentRouteName;
      String? previousRouteName = AppRouteObserver.observer.previousRouteName;
      if ((currentRouteName == CollectionDetailScreenHelper.routeName ||
              currentRouteName == PerformerDetailScreenHelper.routeName) &&
          AppRouteObserver.observer.type == AppRouteChangeType.push) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.detail,
        );
      }
      if (AppRouteObserver.observer.type == AppRouteChangeType.pop &&
          previousRouteName?.endsWith('Alert') != true &&
          previousRouteName?.endsWith('Sheet') != true &&
          previousRouteName != null) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.pop,
        );
      }
    });

    ///手动操作播放监听
    PlayerPlayback.instance.player.playStatusStream.listen((playState) {
      if (playState.isAuto == false &&
          playState.state != PlayState.triggerSeek) {
        String? previousRouteName = AppRouteObserver.observer.previousRouteName;
        if (playState.state == PlayState.playIndex &&
            previousRouteName != QueueListPanel.routeName) {
          showScene(
            scene: AdvertisingScene.inApp,
            detailScene: AdvertisingDetailScene.playStart,
          );
        } else {
          showScene(
            scene: AdvertisingScene.inApp,
            detailScene: AdvertisingDetailScene.play,
          );
        }
      }
    });

    PlayerPlayback.instance.playModeInfo.addListener(() {
      if (PlayerPlayback.instance.playModeInfo.value.isAuto == false) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.play,
        );
      }
    });

    ///网络请求监听
    NetworkManager.httpStatusStream.listen((httpStatus) {
      if (httpStatus.status == AppNetworkState.loading) {
        //搜索主页接口
        if (httpStatus.url ==
                MusicCatalogGateway.baseUrl + MusicCatalogEndpoints.search ||
            httpStatus.url ==
                MusicCatalogGateway.ytBaseUrl +
                    MusicCatalogEndpoints.ytSearch) {
          showScene(
            scene: AdvertisingScene.inApp,
            detailScene: AdvertisingDetailScene.search,
          );
        }
      }
    });

    ///点击收藏监听
    BookmarkMediaState.favoriteStream.listen((e) {
      showScene(
        scene: AdvertisingScene.inApp,
        detailScene: AdvertisingDetailScene.collection,
      );
    });
    BookmarkPerformerState.favoriteStream.listen((e) {
      showScene(
        scene: AdvertisingScene.inApp,
        detailScene: AdvertisingDetailScene.collection,
      );
    });
    BookmarkCollectionState.favoriteStream.listen((e) {
      if (e.id?.startsWith(NewCollectionDialog.createPlaylistNamePrefix) ==
          false) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.collection,
        );
      }
    });

    ///点击下载监听
    MediaTransferService.downloadStartStream.listen((downloadStartInfo) {
      if (downloadStartInfo.isClick) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.download,
        );
      }
    });

    ///播放音乐时广告静音
    PlayerPlayback.instance.player.isLoading.addListener(() async {
      if (PlayerPlayback.instance.player.isLoading.value == true) {
        if (isMuted == false) {
          isMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      }
    });
    PlayerPlayback.instance.player.isPlaying.addListener(() async {
      if (PlayerPlayback.instance.player.isPlaying.value == true) {
        if (isMuted == false) {
          isMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      } else {
        await Future.delayed(Duration(seconds: 2));
        if (PlayerPlayback.instance.player.isLoading.value == false &&
            PlayerPlayback.instance.player.isPlaying.value == false) {
          isMuted = false;
          MobileAds.instance.setAppMuted(false);
        }
      }
    });
  }
}
