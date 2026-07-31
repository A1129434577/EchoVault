import 'dart:async';
import 'dart:io';
import 'package:ad/ad.dart';
import 'package:echo_vault/core/monetization/advertising_display_coordinator.dart';
import 'package:echo_vault/core/configuration/remote_feature_settings.dart';

export 'package:ad/ad.dart';

class AdvertisingCoordinator {
  ///测试单元 ID
  static String defaultAdmobOpenAdId = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/1852258435';
  static String defaultAdmobInterstitialAdId = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/9217788739';
  static String defaultAdmobRewardedAdId = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/1423059197';
  static String defaultAdmobBannerAdId = Platform.isAndroid ? '' : '';
  static String defaultAdmobNativeAdId = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/7713135377';

  static final Map<AdScene, List<AdUnitRemoteConfig>> _defaultAllConfigs = {
    AdvertisingScene.open: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 1,
        type: AdFormatType.open,
        id: defaultAdmobOpenAdId,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.interstitial,
        id: defaultAdmobInterstitialAdId,
      ),
    ],
    AdvertisingScene.inApp: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 2,
        type: AdFormatType.rewarded,
        id: defaultAdmobRewardedAdId,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 1,
        type: AdFormatType.interstitial,
        id: defaultAdmobInterstitialAdId,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.native,
        id: defaultAdmobNativeAdId,
      ),
    ],
    AdvertisingScene.searchNative: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.native,
        id: defaultAdmobNativeAdId,
      ),
    ],
  };

  static Future initializeAdSdk() async {
    _defaultAllConfigs.addAll({
      AdvertisingScene.searchNative1:
          _defaultAllConfigs[AdvertisingScene.searchNative]!,
      AdvertisingScene.libraryNative:
          _defaultAllConfigs[AdvertisingScene.searchNative]!,
      AdvertisingScene.playNative:
          _defaultAllConfigs[AdvertisingScene.searchNative]!,
    });
    AdHelper.openAppWaitSeconds = 8;
    await AdHelper.init(
      defaultAllConfigs: _defaultAllConfigs,
      isNeedUMP: false,
      isAdInvalidAutoFill: false,
    );
    await RemoteFeatureSettings.getUpdateRemoteAdConfig();

    AdvertisingDisplayCoordinator.start();
  }
}

class AdvertisingDetailScene {
  static AdDetailScene coldOpen = AdDetailScene(tag: 'cold');
  static AdDetailScene hotOpen = AdDetailScene(tag: 'hot');
  static AdDetailScene pop = AdDetailScene(tag: 'pop');
  static AdDetailScene playStart = AdDetailScene(tag: 'playStart');
  static AdDetailScene play = AdDetailScene(tag: 'play');
  static AdDetailScene detail = AdDetailScene(tag: 'detail');
  static AdDetailScene search = AdDetailScene(tag: 'search');
  static AdDetailScene library = AdDetailScene(tag: 'library');
  static AdDetailScene collection = AdDetailScene(tag: 'like');
  static AdDetailScene download = AdDetailScene(tag: 'download');
}

class AdvertisingScene {
  //开屏广告位
  static AdScene open = AdScene(name: 'open');
  //播放广告位
  static AdScene inApp = AdScene(
    name: 'in_app',
    isAppInBackgroundNotDisplay: true,
  );
  //搜索原生广告位tab search
  static AdScene searchNative = AdScene(
    name: 'search_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //搜索原生广告位home search
  static AdScene searchNative1 = AdScene(
    name: 'search_native1',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //library原生广告位
  static AdScene libraryNative = AdScene(
    name: 'library_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //播放原生广告位
  static AdScene playNative = AdScene(
    name: 'play_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
}
