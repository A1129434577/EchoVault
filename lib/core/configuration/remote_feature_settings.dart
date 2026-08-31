import 'dart:async';
import 'dart:convert';

import 'package:echo_vault/features/launch/controllers/launch_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/shared/dialogs/upgrade_dialog.dart';
import 'package:echo_vault/core/persistence/media_repository.dart';
import 'package:echo_vault/core/persistence/user_preference_keys.dart';
import 'package:echo_vault/core/media/media_origin.dart';
import 'package:echo_vault/firebase_options.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/discovery/controllers/discovery_state.dart';
import 'package:echo_vault/core/utilities/notification_helper.dart';
import 'package:echo_vault/utils/string_cipher.dart';

class RemoteFeatureSettings {
  static Completer remoteServiceReady = Completer();
  static Completer remoteServiceUpdated = Completer();

  static Future<void> getUpdateRemoteAdConfig({
    String? adConfigArg,
    bool isNeedSetArg = true,
  }) async {
    try {
      if (adConfigArg == null) {
        SharedPreferences spLocal = await SharedPreferences.getInstance();
        adConfigArg = spLocal.getString(UserPreferenceKeys.remoteAdConfig);
      } else {
        SharedPreferences.getInstance().then((spInputArg) {
          spInputArg.setString(UserPreferenceKeys.remoteAdConfig, adConfigArg!);
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
      if (remoteServiceReady.isCompleted == false) {
        remoteServiceReady.complete();
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
    if(remoteServiceUpdated.isCompleted==false){
      remoteServiceUpdated.complete();
      LaunchState.instance.fetchModulesUsable();
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
      UpgradeDialog.releaseUrl = updateLinkLocal;
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
          source: MediaOrigin.homeRecommendations,
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

class RemoteAdUnitParser {
  static Widget closeButton() {
    return Container(
      height: 24,
      width: 24,
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
    AdFormatType typeLocal = AdFormatType.fromValue(
      jsonArg[AdRemoteParser.formatField],
    );
    AdUnitRemoteConfig unitRemoteConfigLocal = AdUnitRemoteConfig(
      id: jsonArg[AdRemoteParser.unitIdField] as String?,
      type: typeLocal,
      source: AdSource.fromValue(jsonArg[AdRemoteParser.providerField]),
      level: jsonArg[AdRemoteParser.priorityField] ?? 0,
    );
    if (typeLocal == AdFormatType.native || typeLocal == AdFormatType.banner) {
      unitRemoteConfigLocal.closeButtonBuilder = () {
        return closeButton();
      };
      unitRemoteConfigLocal.size = AdSize(
        width: (AdHelper.screenWidth - 16 * 2).toInt(),
        height: (((AdHelper.screenWidth - 16 * 2)) * (250 / 300)).toInt(),
      );
    }
    return unitRemoteConfigLocal;
  }
}

class AdRemoteParser {
  static const String unitIdField = 'adid';
  static const String formatField = 'adtype';
  static const String providerField = 'adsource';
  static const String priorityField = 'adlevel';

  static AdRemoteConfig fromJson(Map jsonArg) {
    Map<AdScene, List<AdUnitRemoteConfig>> adSceneConfigLocal = {};
    jsonArg.forEach((keyInputArg, currentValue) {
      AdScene? adSceneLocal = AdScene.fromName(keyInputArg);
      if (adSceneLocal != null) {
        List configListLocal = currentValue;
        List<AdUnitRemoteConfig> adUnitListLocal = configListLocal.cast<Map>().map((entry) {
          AdUnitRemoteConfig unitLocal = RemoteAdUnitParser.fromJson(entry);
          return unitLocal;
        }).toList();
        adSceneConfigLocal[adSceneLocal] = adUnitListLocal;
        if (adSceneLocal == AdvertisingScene.searchResultsNative) {
          adSceneConfigLocal[AdvertisingScene.searchHomeNative] = adUnitListLocal;
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
