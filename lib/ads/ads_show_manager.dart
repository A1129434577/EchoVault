
import 'package:player_base/utils/debounce_util.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/alerts/playing_list_sheet.dart';
import 'package:echo_vault/alerts/rate_alert.dart';
import 'package:echo_vault/controllers/favorite_artist_controller.dart';
import 'package:echo_vault/controllers/favorite_file_controller.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/controllers/file_downloader.dart';
import 'package:echo_vault/modules/artist/artist_detail_page.dart';
import 'package:echo_vault/modules/artist/widgets/favorite_artist_widget.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';
import 'package:echo_vault/network/ytm_network.dart';

class AdsShowManager {
  static final String _rateAlertShowCountKey = '_rateAlertShowCountKey';
  static final String _rateAlertLastShowTimeKey = '_rateAlertLastShowTimeKey';
  static int? rateAlertLastShowTime;
  static bool isMuted = false;

  static final DebounceUtil _debounce = DebounceUtil();


  static Future<bool?> showScene({required AdScene scene, AdDetailScene? detailScene, bool verifyCd=true, dynamic params}) async {
    return _debounce<Future<bool?>>(Duration(milliseconds: 1500), () async {
      bool? showSuccess = await AdHelper.showScene(scene: scene, detailScene: detailScene, verifyCd: verifyCd, params: params);
      if(showSuccess!=true){
        //搜索、下载、收藏或者播放的时候出现好评引导
        if(detailScene==AdsManagerDetailScene.search ||
            detailScene==AdsManagerDetailScene.download ||
            detailScene==AdsManagerDetailScene.collection ||
            detailScene==AdsManagerDetailScene.play){
          DateTime now = DateTime.now();
          if(now.difference(DateTime.fromMillisecondsSinceEpoch(appIsFirstInTimeForRate??0)).inHours>24){
            rateAlertLastShowTime = AdHelper.sharedPreferences.getInt(_rateAlertLastShowTimeKey);
            if(now.difference(DateTime.fromMillisecondsSinceEpoch(rateAlertLastShowTime??0)).inHours>24) {
              int rateAlertShowCount = AdHelper.sharedPreferences.getInt(_rateAlertShowCountKey)??0;
              if(rateAlertShowCount<5) {
                RateAlert.show();
                AdHelper.sharedPreferences.setInt(_rateAlertLastShowTimeKey, DateTime.now().millisecondsSinceEpoch);
                rateAlertShowCount++;
                AdHelper.sharedPreferences.setInt(_rateAlertShowCountKey, rateAlertShowCount);
              }
            }
          }
        }
      }
      return showSuccess;
    });
  }

  static final String _appIsFirstInTimeForRateKey = '_appIsFirstInTimeForRateKey';
  static int? appIsFirstInTimeForRate;

  static void start() async {
    appIsFirstInTimeForRate = AdHelper.sharedPreferences.getInt(_appIsFirstInTimeForRateKey);
    if(appIsFirstInTimeForRate == null){
      AdHelper.sharedPreferences.setInt(_appIsFirstInTimeForRateKey, DateTime.now().millisecondsSinceEpoch);
    }

    //前后台监听
    AppLifecycleObserver.lifecycleStream.listen((state){
      if(state==AppLifecycleState.foreground){
        showScene(scene: AdsManagerScene.open, detailScene: AdsManagerDetailScene.hotOpen);
      }
    });

    ///路由监听
    AppRouteObserver.observer.addListener((){
      String? currentRouteName = AppRouteObserver.observer.currentRouteName;
      String? previousRouteName = AppRouteObserver.observer.previousRouteName;
      if((currentRouteName == PlaylistDetailPageUtil.routeName || currentRouteName == ArtistDetailPageUtil.routeName) && AppRouteObserver.observer.type==AppRouteChangeType.push){
        showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.detail);
      }
      if(AppRouteObserver.observer.type==AppRouteChangeType.pop
          && previousRouteName?.endsWith('Alert')!=true
          && previousRouteName?.endsWith('Sheet')!=true
          && previousRouteName!=null){
        showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.pop);
      }
    });

    ///手动操作播放监听
    PlayerPlayback.instance.player.playStatusStream.listen((playState){
      if(playState.isAuto==false && playState.state!=PlayState.triggerSeek) {
        String? previousRouteName = AppRouteObserver.observer.previousRouteName;
        if(playState.state == PlayState.playIndex && previousRouteName!=PlayingListSheet.routeName){
          showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.playStart);
        }else{
          showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.play);
        }
      }
    });

    PlayerPlayback.instance.playModeInfo.addListener((){
      if(PlayerPlayback.instance.playModeInfo.value.isAuto==false) {
        showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.play);
      }
    });

    ///网络请求监听
    NetworkManager.httpStatusStream.listen((httpStatus){
      if(httpStatus.status==AppNetworkState.loading){
        //搜索主页接口
        if(httpStatus.url == YTMNetwork.baseUrl+YTMApis.search||
            httpStatus.url == YTMNetwork.ytBaseUrl+YTMApis.ytSearch){
          showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.search);
        }
      }
    });

    ///点击收藏监听
    FavoriteFileController.favoriteStream.listen((e){
      showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.collection);
    });
    FavoriteArtistController.favoriteStream.listen((e){
      showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.collection);
    });
    FavoriteGroupController.favoriteStream.listen((e){
      if(e.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==false) {
        showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.collection);
      }
    });

    ///点击下载监听
    FileDownloader.downloadStartStream.listen((downloadStartInfo){
      if(downloadStartInfo.isClick){
        showScene(scene: AdsManagerScene.inApp, detailScene: AdsManagerDetailScene.download);
      }
    });

    ///播放音乐时广告静音
    PlayerPlayback.instance.player.isLoading.addListener(() async {
      if(PlayerPlayback.instance.player.isLoading.value==true){
        if(isMuted==false){
          isMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      }
    });
    PlayerPlayback.instance.player.isPlaying.addListener(() async {
      if(PlayerPlayback.instance.player.isPlaying.value==true){
        if(isMuted==false) {
          isMuted = true;
          MobileAds.instance.setAppMuted(true);
        }
      }else{
        await Future.delayed(Duration(seconds: 2));
        if(PlayerPlayback.instance.player.isLoading.value==false &&
            PlayerPlayback.instance.player.isPlaying.value==false) {
          isMuted = false;
          MobileAds.instance.setAppMuted(false);
        }
      }
    });
  }
}