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
  static int rateAlertLastShowTime = DateTime.now().millisecondsSinceEpoch;
  static bool isMuted = false;

  static final DebounceUtil _debounce = DebounceUtil();


  static Future<bool?> showScene({
    required AdScene scene,
    AdDetailScene? detailScene,
    bool verifyCd = true,
    dynamic params,
  }) async {
    return _debounce<Future<bool?>>(Duration(milliseconds: 1500), () async {
      bool? showSuccessValueLocal = await AdHelper.showScene(
        scene: scene,
        detailScene: detailScene,
        verifyCd: verifyCd,
        params: params,
      );
      if (showSuccessValueLocal != true) {
        //搜索、下载、收藏或者播放的时候出现好评引导
        if (detailScene == AdvertisingDetailScene.search ||
            detailScene == AdvertisingDetailScene.download ||
            detailScene == AdvertisingDetailScene.collection ||
            detailScene == AdvertisingDetailScene.play) {
          DateTime nowLocal = DateTime.now();
          if (nowLocal
              .difference(
            DateTime.fromMillisecondsSinceEpoch(rateAlertLastShowTime),
          )
              .inHours >
              24) {
            int rateAlertShowCountLocal =
                AdHelper.sharedPreferences.getInt(_rateAlertShowCountKey) ??
                    0;
            if (rateAlertShowCountLocal < 5) {
              RatingDialog.show();
              AdHelper.sharedPreferences.setInt(
                _rateAlertLastShowTimeKey,
                DateTime.now().millisecondsSinceEpoch,
              );
              rateAlertShowCountLocal++;
              AdHelper.sharedPreferences.setInt(
                _rateAlertShowCountKey,
                rateAlertShowCountLocal,
              );
            }
          }
        }
      }
      return showSuccessValueLocal;
    });
  }

  static void start() async {
    int? rateAlertLastShowTimeNew = AdHelper.sharedPreferences.getInt(_rateAlertLastShowTimeKey);
    if(rateAlertLastShowTimeNew == null){
      AdHelper.sharedPreferences.setInt(_rateAlertLastShowTimeKey, rateAlertLastShowTime);
    }else{
      rateAlertLastShowTime = rateAlertLastShowTimeNew;
    }

    //前后台监听
    AppLifecycleObserver.lifecycleStream.listen((stateArg) {
      if (stateArg == AppLifecycleState.foreground) {
        showScene(
          scene: AdvertisingScene.open,
          detailScene: AdvertisingDetailScene.hotOpen,
        );
      }
    });

    ///路由监听
    AppRouteObserver.observer.addListener(() {
      String? currentRouteNameLocal =
          AppRouteObserver.observer.currentRouteName;
      String? previousRouteNameLocal =
          AppRouteObserver.observer.previousRouteName;
      if ((currentRouteNameLocal == CollectionDetailScreenHelper.routeName ||
              currentRouteNameLocal == PerformerDetailScreenHelper.routeName) &&
          AppRouteObserver.observer.type == AppRouteChangeType.push) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.detail,
        );
      }
      if (AppRouteObserver.observer.type == AppRouteChangeType.pop &&
          previousRouteNameLocal?.endsWith('Alert') != true &&
          previousRouteNameLocal?.endsWith('Sheet') != true &&
          previousRouteNameLocal != null) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.pop,
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
            previousRouteNameLocal != QueueListPanel.routeName) {
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
    NetworkManager.httpStatusStream.listen((httpStatusInputArg) {
      if (httpStatusInputArg.status == AppNetworkState.loading) {
        //搜索主页接口
        if (httpStatusInputArg.url ==
                MusicCatalogGateway.baseUrl + MusicCatalogEndpoints.search ||
            httpStatusInputArg.url ==
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
    BookmarkMediaState.favoriteStream.listen((entry) {
      showScene(
        scene: AdvertisingScene.inApp,
        detailScene: AdvertisingDetailScene.collection,
      );
    });
    BookmarkPerformerState.favoriteStream.listen((entry) {
      showScene(
        scene: AdvertisingScene.inApp,
        detailScene: AdvertisingDetailScene.collection,
      );
    });
    BookmarkCollectionState.favoriteStream.listen((entry) {
      if (entry.id?.startsWith(NewCollectionDialog.createPlaylistNamePrefix) ==
          false) {
        showScene(
          scene: AdvertisingScene.inApp,
          detailScene: AdvertisingDetailScene.collection,
        );
      }
    });

    ///点击下载监听
    MediaTransferService.downloadStartStream.listen((
      downloadStartInfoInputArg,
    ) {
      if (downloadStartInfoInputArg.isClick) {
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
