import 'dart:async';
import 'dart:io';
import 'package:ad/ad.dart';
import 'package:echo_vault/core/monetization/advertising_display_coordinator.dart';
import 'package:echo_vault/core/configuration/remote_feature_settings.dart';

export 'package:ad/ad.dart';

class AdvertisingCoordinator {
  ///测试单元 ID
  static String fallbackLaunchAdUnit = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/1852258435';
  static String fallbackInterstitialUnit = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/9217788739';
  static String fallbackRewardedUnit = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/1423059197';
  static String fallbackBannerUnit = Platform.isAndroid ? '' : '';
  static String fallbackNativeUnit = Platform.isAndroid
      ? ''
      : 'ca-app-pub-6383874853723176/7713135377';

  static final Map<AdScene, List<AdUnitRemoteConfig>> _fallbackPlacements = {
    AdvertisingScene.appLaunch: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 1,
        type: AdFormatType.open,
        id: fallbackLaunchAdUnit,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.interstitial,
        id: fallbackInterstitialUnit,
      ),
    ],
    AdvertisingScene.fullScreen: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 2,
        type: AdFormatType.rewarded,
        id: fallbackRewardedUnit,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 1,
        type: AdFormatType.interstitial,
        id: fallbackInterstitialUnit,
      ),
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.native,
        id: fallbackNativeUnit,
      ),
    ],
    AdvertisingScene.searchResultsNative: [
      AdUnitRemoteConfig(
        source: AdSource.admob,
        level: 0,
        type: AdFormatType.native,
        id: fallbackNativeUnit,
      ),
    ],
  };

  static Future initializeAdSdk() async {
    _fallbackPlacements.addAll({
      AdvertisingScene.searchHomeNative:
          _fallbackPlacements[AdvertisingScene.searchResultsNative]!,
      AdvertisingScene.libraryFeedNative:
          _fallbackPlacements[AdvertisingScene.searchResultsNative]!,
      AdvertisingScene.playbackNative:
          _fallbackPlacements[AdvertisingScene.searchResultsNative]!,
    });
    AdHelper.openAppWaitSeconds = 8;
    await AdHelper.init(
      defaultAllConfigs: _fallbackPlacements,
      isNeedUMP: false,
      isAdInvalidAutoFill: false,
    );
    await RemoteFeatureSettings.getUpdateRemoteAdConfig();

    AdvertisingDisplayCoordinator.start();
  }
}

class AdvertisingDetailScene {
  static AdDetailScene coldLaunch = AdDetailScene(tag: 'cold');
  static AdDetailScene warmResume = AdDetailScene(tag: 'hot');
  static AdDetailScene popup = AdDetailScene(tag: 'pop');
  static AdDetailScene playbackStart = AdDetailScene(tag: 'playStart');
  static AdDetailScene playback = AdDetailScene(tag: 'play');
  static AdDetailScene details = AdDetailScene(tag: 'detail');
  static AdDetailScene searchResults = AdDetailScene(tag: 'search');
  static AdDetailScene mediaLibrary = AdDetailScene(tag: 'library');
  static AdDetailScene savedCollection = AdDetailScene(tag: 'like');
  static AdDetailScene mediaDownload = AdDetailScene(tag: 'download');

  static AdDetailScene get play => playback;
}

class AdvertisingScene {
  //开屏广告位
  static AdScene appLaunch = AdScene(name: 'open');
  //播放广告位
  static AdScene fullScreen = AdScene(
    name: 'in_app',
    isAppInBackgroundNotDisplay: true,
  );
  //搜索原生广告位tab search
  static AdScene searchResultsNative = AdScene(
    name: 'search_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //搜索原生广告位home search
  static AdScene searchHomeNative = AdScene(
    name: 'search_native1',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //library原生广告位
  static AdScene libraryFeedNative = AdScene(
    name: 'library_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );
  //播放原生广告位
  static AdScene playbackNative = AdScene(
    name: 'play_native',
    isNeedAutoLoad: false,
    isFullScreen: false,
    isAddToInterval: false,
  );

  static AdScene get inApp => fullScreen;
}
