import 'package:flutter/services.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/core/configuration/remote_feature_settings.dart';
import 'package:echo_vault/core/state/transfer_media_state.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/core/networking/playback_http_transport.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';
import 'package:echo_vault/features/launch/controllers/launch_state.dart';

class ApplicationSettings {
  static Future start() async {
    SharedPreferences spLocal = await SharedPreferences.getInstance();
    LaunchState.instance.isModulesUsable.value = spLocal.getBool(
      UserPreferenceKeys.modulesEnabled,
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    AppLifecycleObserver.lifecycleStream.listen((stateArg) {
      if (stateArg == AppLifecycleState.foreground) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });

    //下载
    await TransferMediaState.initializeSdk();

    //播放相关
    PlayerBase.init(
      mediaSources: MediaOrigin.availableSources,
      encryptKey: 'kBNsiwy79vx5N56e37+qBqhZTSSKVfT5LIxfP90AYyw=',
    );
    await PlayerPlayback.instance.init(PlaybackHttpTransport());

    //云控(注意：不要去await Firebase初始化，因为发现它会影响AdMob广告的初始化和请求)
    await RemoteFeatureSettings.init();

    await AdvertisingCoordinator.initializeAdSdk();
  }
}
