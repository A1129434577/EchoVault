
import 'package:flutter/services.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/config/f_remote_config.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/enums/file_source.dart';
import 'package:echo_vault/network/player_http_client.dart';
import 'package:echo_vault/modules/open/controllers/open_controller.dart';

class AppConfig {
  static Future start() async {

    SharedPreferences sp = await SharedPreferences.getInstance();
    OpenController.instance.isModulesUsable.value = sp.getBool(OpenController.isModulesUsableKey);

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    AppLifecycleObserver.lifecycleStream.listen((state){
      if(state==AppLifecycleState.foreground){
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });

    //下载
    await DownloadFileController.initSdk();

    //播放相关
    PlayerBase.init(mediaSources: FileSource.sources, encryptKey: 'kBNsiwy79vx5N56e37+qBqhZTSSKVfT5LIxfP90AYyw=');
    await PlayerPlayback.instance.init(PlayerHttpClient());

    //云控(注意：不要去await Firebase初始化，因为发现它会影响AdMob广告的初始化和请求)
    await FRemoteConfig.init();

    await AdsManager.initAdSdk();
  }
}