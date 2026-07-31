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

class AdRemoteParser {
  static const String idKey = 'adid';
  static const String typeKey = 'adtype';
  static const String sourceKey = 'adsource';
  static const String levelKey = 'adlevel';

  static AdRemoteConfig fromJson(Map jsonArg) {
    Map<AdScene, List<AdUnitRemoteConfig>> adSceneConfigLocal = {};
    jsonArg.forEach((keyInputArg, currentValue) {
      AdScene? adSceneLocal = AdScene.fromName(keyInputArg);
      if (adSceneLocal != null) {
        List configListLocal = currentValue;
        List<AdUnitRemoteConfig> adUnitListLocal = configListLocal
            .cast<Map>()
            .map((entry) {
              AdUnitRemoteConfig unitLocal = _RemoteAdUnitParser.fromJson(
                entry,
              );
              return unitLocal;
            })
            .toList();
        adSceneConfigLocal[adSceneLocal] = adUnitListLocal;
        if (adSceneLocal == AdvertisingScene.searchNative) {
          adSceneConfigLocal[AdvertisingScene.searchNative1] = adUnitListLocal;
          adSceneConfigLocal[AdvertisingScene.libraryNative] = adUnitListLocal;
          adSceneConfigLocal[AdvertisingScene.playNative] = adUnitListLocal;
        }
      }
    });
    return AdRemoteConfig(
      adSceneConfig: adSceneConfigLocal,
      adIntervalSeconds: jsonArg['adinterval'],
      loadTimeOut: 30,
    );
  }
}

class RemoteFeatureSettings {
  static Completer firebaseInitCompleter = Completer();

  static Completer<String> modelCompleter = Completer();

  static const String _adConfigStringKey = '_adConfigStringKey';
  static Future<void> getUpdateRemoteAdConfig({
    String? adConfigArg,
    bool isNeedSetArg = true,
  }) async {
    try {
      if (adConfigArg == null) {
        SharedPreferences spLocal = await SharedPreferences.getInstance();
        adConfigArg = spLocal.getString(_adConfigStringKey);
      } else {
        SharedPreferences.getInstance().then((spInputArg) {
          spInputArg.setString(_adConfigStringKey, adConfigArg!);
        });
      }
      if (adConfigArg?.isNotEmpty != true) return;
      Map adConfigMapLocal = jsonDecode(adConfigArg!);
      if (isNeedSetArg == false) return;
      AdHelper.setAdConfig(AdRemoteParser.fromJson(adConfigMapLocal));
    } catch (_) {}
  }

  static Future<void> init() async {
    if (await EventsInfoUtil.isFirstIn) {
      _initializeRecommendList();
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (firebaseInitCompleter.isCompleted == false) {
        firebaseInitCompleter.complete();
      }

      FirebaseRemoteConfig firebaseConfigLocal = FirebaseRemoteConfig.instance;
      firebaseConfigLocal
          .setConfigSettings(
            RemoteConfigSettings(
              minimumFetchInterval: const Duration(hours: 24),
              fetchTimeout: const Duration(minutes: 1),
            ),
          )
          .then((currentValue) async {
            try {
              await firebaseConfigLocal.fetchAndActivate();
              applyUpgradeConfig();
            } catch (_) {}
            firebaseConfigLocal.onConfigUpdated.listen((eventInputArg) async {
              try {
                await firebaseConfigLocal.activate();
                applyUpgradeConfig();
              } catch (_) {}
            });
          });
    } catch (_) {}
  }

  static void applyUpgradeConfig() async {
    ///用户模式云控
    try {
      String versionLocal = FirebaseRemoteConfig.instance.getString('version');
      if (!modelCompleter.isCompleted) {
        modelCompleter.complete(versionLocal);
      }
    } catch (_) {
      modelCompleter.complete('');
    }

    ///广告云控
    try {
      String adConfigLocal = FirebaseRemoteConfig.instance.getString(
        'all_config',
      );
      getUpdateRemoteAdConfig(adConfigArg: adConfigLocal);
    } catch (_) {}

    ///本地推送云控
    try {
      int viaTimerPushLocal = FirebaseRemoteConfig.instance.getInt(
        'push_notice',
      );
      NotificationHelper.pushConfig = viaTimerPushLocal;
    } catch (_) {}

    ///引流弹窗云控
    try {
      int isNeedUpdateLocal = FirebaseRemoteConfig.instance.getInt(
        'update_switch',
      );
      UpgradeDialog.updateType = UpdateType.values[isNeedUpdateLocal];
      String updateLinkLocal = FirebaseRemoteConfig.instance.getString(
        'update_link',
      );
      UpgradeDialog.updateLink = updateLinkLocal;
    } catch (_) {}
  }

  static Future _initializeRecommendList() async {
    try {
      final encryptedJsonLocal = await rootBundle.loadString(
        Assets.data.fileSeed,
      );
      String recommendJsonLocal = StringCipher.decrypt(encryptedJsonLocal);
      List recommendLocal = jsonDecode(recommendJsonLocal);
      List<FileInfo> suggestedItems = [];
      for (Map fileMap in recommendLocal.cast<Map>()) {
        final fileIdLocal = fileMap['song_id'];
        FileInfo mediaEntry = FileInfo(
          extension: 'mp4',
          source: MediaOrigin.homeReco,
          fileId: fileIdLocal,
          thumbnail: 'https://i.ytimg.com/vi/$fileIdLocal/default.jpg',
          name: fileMap['name'],
          artist: fileMap['artist'],
        );
        suggestedItems.insert(0, mediaEntry);
        MediaRepository.addFileInfo(mediaEntry);
      }
      DiscoveryState.instance.recommendList.value = suggestedItems;
    } catch (_) {}
  }
}

class _RemoteAdUnitParser {
  static Widget closeButton(double sizeArg) {
    return Container(
      height: sizeArg,
      width: sizeArg,
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 6, left: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withAlpha((255 * 0.5).round()),
      ),
      child: Icon(Icons.close, size: 15, color: Colors.white),
    );
  }

  static AdUnitRemoteConfig fromJson(Map jsonArg) {
    //0-100
    double? nativeHitProbabilityValueLocal = double.tryParse(
      (jsonArg['native_hit']).toString(),
    );
    double? nativeCoseSizeValueLocal = double.tryParse(
      (jsonArg['native_close_size']).toString(),
    );
    int? nativeShowSecondsValueLocal = double.tryParse(
      (jsonArg['native_time']).toString(),
    )?.toInt();

    AdFormatType typeLocal = AdFormatType.fromValue(
      jsonArg[AdRemoteParser.typeKey],
    );
    AdUnitRemoteConfig unitRemoteConfigLocal = AdUnitRemoteConfig(
      id: jsonArg[AdRemoteParser.idKey] as String?,
      type: typeLocal,
      source: AdSource.fromValue(jsonArg[AdRemoteParser.sourceKey]),
      level: jsonArg[AdRemoteParser.levelKey] ?? 0,
    );
    if (typeLocal == AdFormatType.native || typeLocal == AdFormatType.banner) {
      unitRemoteConfigLocal.aspectRatio = 300 / 180;
      unitRemoteConfigLocal.closeButtonBuilder =
          nativeCoseSizeValueLocal != null
          ? () {
              return closeButton(nativeCoseSizeValueLocal);
            }
          : null;
      unitRemoteConfigLocal.backgroundBuilder = () {
        return Container(color: Color(0xffA68DFE));
      };
      unitRemoteConfigLocal.nativeShowSeconds = nativeShowSecondsValueLocal;
      unitRemoteConfigLocal.nativeHitProbability =
          nativeHitProbabilityValueLocal;
      unitRemoteConfigLocal.size = AdSize(
        width: (AdHelper.screenWidth - 16 * 2).toInt(),
        height: (((AdHelper.screenWidth - 16 * 2)) * (250 / 300)).toInt(),
      );
    }
    return unitRemoteConfigLocal;
  }
}
