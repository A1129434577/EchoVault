import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/upgrade_dialog.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/firebase_options.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/core/utilities/notification_helper.dart';
import 'package:echo_vault/utils/string_cipher.dart';

class RemoteFeatureSettings {
  static Completer firebaseInitCompleter = Completer();

  static Future<void> init() async {
    if (await EventsInfoUtil.isFirstIn) {
      _initRecommendList();
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (firebaseInitCompleter.isCompleted == false) {
        firebaseInitCompleter.complete();
      }

      FirebaseRemoteConfig firebaseConfig = FirebaseRemoteConfig.instance;
      firebaseConfig
          .setConfigSettings(
            RemoteConfigSettings(
              minimumFetchInterval: const Duration(hours: 24),
              fetchTimeout: const Duration(minutes: 1),
            ),
          )
          .then((value) async {
            try {
              await firebaseConfig.fetchAndActivate();
              upgradeConfig();
            } catch (_) {}
            firebaseConfig.onConfigUpdated.listen((event) async {
              try {
                await firebaseConfig.activate();
                upgradeConfig();
              } catch (_) {}
            });
          });
    } catch (_) {}
  }

  static Completer<String> modelCompleter = Completer();
  static void upgradeConfig() async {
    ///用户模式云控
    try {
      String version = FirebaseRemoteConfig.instance.getString('version');
      if (!modelCompleter.isCompleted) {
        modelCompleter.complete(version);
      }
    } catch (_) {
      modelCompleter.complete('');
    }

    ///广告云控
    try {
      String adConfig = FirebaseRemoteConfig.instance.getString('all_config');
      getUpdateRemoteAdConfig(adConfig: adConfig);
    } catch (_) {}

    ///本地推送云控
    try {
      int viaTimerPush = FirebaseRemoteConfig.instance.getInt('push_notice');
      NotificationHelper.pushConfig = viaTimerPush;
    } catch (_) {}

    ///引流弹窗云控
    try {
      int isNeedUpdate = FirebaseRemoteConfig.instance.getInt('update_switch');
      UpgradeDialog.updateType = UpdateType.values[isNeedUpdate];
      String updateLink = FirebaseRemoteConfig.instance.getString(
        'update_link',
      );
      UpgradeDialog.updateLink = updateLink;
    } catch (_) {}
  }

  static const String _adConfigStringKey = '_adConfigStringKey';
  static Future<void> getUpdateRemoteAdConfig({
    String? adConfig,
    bool isNeedSet = true,
  }) async {
    try {
      if (adConfig == null) {
        SharedPreferences sp = await SharedPreferences.getInstance();
        adConfig = sp.getString(_adConfigStringKey);
      } else {
        SharedPreferences.getInstance().then((sp) {
          sp.setString(_adConfigStringKey, adConfig!);
        });
      }
      if (adConfig?.isNotEmpty != true) return;
      Map adConfigMap = jsonDecode(adConfig!);
      if (isNeedSet == false) return;
      AdHelper.setAdConfig(AdRemoteParser.fromJson(adConfigMap));
    } catch (_) {}
  }

  static Future _initRecommendList() async {
    try {
      final encryptedJson = await rootBundle.loadString(
        Assets.data.fileSeed,
      );
      String recommendJson = StringCipher.decrypt(encryptedJson);
      List recommend = jsonDecode(recommendJson);
      List<FileInfo> recommendList = [];
      for (Map fileMap in recommend.cast<Map>()) {
        final fileId = fileMap['song_id'];
        FileInfo mediaDetails = FileInfo(
          extension: 'mp4',
          source: MediaOrigin.homeReco,
          fileId: fileId,
          thumbnail: 'https://i.ytimg.com/vi/$fileId/default.jpg',
          name: fileMap['name'],
          artist: fileMap['artist'],
        );
        recommendList.insert(0, mediaDetails);
        MediaRepository.insertFileInfo(mediaDetails);
      }
      DiscoveryState.instance.recommendList.value = recommendList;
    } catch (_) {}
  }
}

class _RemoteAdUnitParser {
  static AdUnitRemoteConfig fromJson(Map json) {
    //0-100
    double? nativeHitProbability = double.tryParse(
      (json['native_hit']).toString(),
    );
    double? nativeCoseSize = double.tryParse(
      (json['native_close_size']).toString(),
    );
    int? nativeShowSeconds = double.tryParse(
      (json['native_time']).toString(),
    )?.toInt();

    AdFormatType type = AdFormatType.fromValue(json[AdRemoteParser.typeKey]);
    AdUnitRemoteConfig unitRemoteConfig = AdUnitRemoteConfig(
      id: json[AdRemoteParser.idKey] as String?,
      type: type,
      source: AdSource.fromValue(json[AdRemoteParser.sourceKey]),
      level: json[AdRemoteParser.levelKey] ?? 0,
    );
    if (type == AdFormatType.native || type == AdFormatType.banner) {
      unitRemoteConfig.aspectRatio = 300 / 180;
      unitRemoteConfig.closeButtonBuilder = nativeCoseSize != null
          ? () {
              return closeButton(nativeCoseSize);
            }
          : null;
      unitRemoteConfig.backgroundBuilder = () {
        return Container(color: Color(0xffA68DFE));
      };
      unitRemoteConfig.nativeShowSeconds = nativeShowSeconds;
      unitRemoteConfig.nativeHitProbability = nativeHitProbability;
      unitRemoteConfig.size = AdSize(
        width: (AdHelper.screenWidth - 16 * 2).toInt(),
        height: (((AdHelper.screenWidth - 16 * 2)) * (250 / 300)).toInt(),
      );
    }
    return unitRemoteConfig;
  }

  static Widget closeButton(double size) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 6, left: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withAlpha((255 * 0.5).round()),
      ),
      child: Icon(Icons.close, size: 15, color: Colors.white),
    );
  }
}

class AdRemoteParser {
  static const String idKey = 'adid';
  static const String typeKey = 'adtype';
  static const String sourceKey = 'adsource';
  static const String levelKey = 'adlevel';

  static AdRemoteConfig fromJson(Map json) {
    Map<AdScene, List<AdUnitRemoteConfig>> adSceneConfig = {};
    json.forEach((key, value) {
      AdScene? adScene = AdScene.fromName(key);
      if (adScene != null) {
        List configList = value;
        List<AdUnitRemoteConfig> adUnitList = configList.cast<Map>().map((e) {
          AdUnitRemoteConfig unit = _RemoteAdUnitParser.fromJson(e);
          return unit;
        }).toList();
        adSceneConfig[adScene] = adUnitList;
        if (adScene == AdvertisingScene.searchNative) {
          adSceneConfig[AdvertisingScene.searchNative1] = adUnitList;
          adSceneConfig[AdvertisingScene.libraryNative] = adUnitList;
          adSceneConfig[AdvertisingScene.playNative] = adUnitList;
        }
      }
    });
    return AdRemoteConfig(
      adSceneConfig: adSceneConfig,
      adIntervalSeconds: json['adinterval'],
      loadTimeOut: 30,
    );
  }
}
