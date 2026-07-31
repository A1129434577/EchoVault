import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:echo_vault/core/configuration/remote_feature_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/monetization/advertising_coordinator.dart';
import 'package:echo_vault/core/monetization/advertising_display_coordinator.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class LaunchState with ChangeNotifier {
  static const String isModulesUsableKey = 'isModulesUsableKey';

  static final LaunchState _instance = LaunchState._();
  static LaunchState get instance => _instance;
  factory LaunchState() {
    return _instance;
  }
  LaunchState._() {
    listenNetwork();
  }

  ValueNotifier<bool?> isModulesUsable = ValueNotifier(null);

  final ValueNotifier<bool> isProgressFinish = ValueNotifier(false);
  StreamSubscription? _adStatusSubscription;

  static bool isNetworkUsable = true;
  Future listenNetwork() async {
    await Future.delayed(Duration(seconds: 5));
    //是否曾经是wifi
    bool? isLastWifi;
    Connectivity connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> connectivityResult,
    ) async {
      try {
        if (connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.ethernet) ||
            connectivityResult.contains(ConnectivityResult.vpn)) {
          isNetworkUsable = true;
          if (isModulesUsable.value == null) {
            if (modulesCompleter.isCompleted) {
              _queryModulesUsable(retryNum: 5);
            }
          }
          //如果曾经是wifi或者第一次检测到是流量，则提示
          if (isLastWifi != false &&
              connectivityResult.contains(ConnectivityResult.wifi) == false) {
            isLastWifi = false;
            MessageOverlay.showWarning(
              'Your Wi-Fi connection is weak. The app is now using your cellular data.'
                  .translate,
            );
          }
          if (connectivityResult.contains(ConnectivityResult.wifi) == true) {
            isLastWifi = true;
          }
        } else {
          isNetworkUsable = false;
          Future.delayed(Duration(seconds: 1), () {
            if (isNetworkUsable == false) {
              MessageOverlay.showWarning(
                'Network Unavailable,Please check your Wi-Fi or mobile data connection and try again.'
                    .translate,
              );
            }
          });
        }
      } catch (_) {}
    });

    ///开始检测网络环境
    connectivity.checkConnectivity();
  }

  late DateTime startTime;
  final Completer modulesCompleter = Completer();
  Future queryModules() async {
    startTime = DateTime.now();
    if (isModulesUsable.value == null) {
      await _queryModulesUsable();
      modulesCompleter.complete();
    } else {
      modulesCompleter.complete();
    }
    return modulesCompleter.future;
  }

  Future _queryModulesUsable({int retryNum = 10}) async {
    String openVersion = await RemoteFeatureSettings.modelCompleter.future;
    if (openVersion.isEmpty) {
      openVersion = '0.0.0';
    }
    openVersion = openVersion.replaceAll('.', '');
    String currentVersionString = await EventsInfoUtil.packageVersion();
    currentVersionString = currentVersionString.replaceAll('.', '');
    int deviation = currentVersionString.length - openVersion.length;
    if (deviation < 0) {
      for (int i = 0; i < deviation.abs(); i++) {
        currentVersionString += '0';
      }
    } else if (deviation > 0) {
      for (int i = 0; i < deviation; i++) {
        openVersion += '0';
      }
    }
    if (int.parse(openVersion) >= int.parse(currentVersionString)) {
      isModulesUsable.value = true;
      SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(isModulesUsableKey, true);
    }

    if (isModulesUsable.value != true && retryNum > 0) {
      await Future.delayed(Duration(milliseconds: 500));
      retryNum--;
      await _queryModulesUsable(retryNum: retryNum);
    }
  }

  Future<bool> loadAndShowAd() async {
    Completer<bool> adCompleter = Completer();
    await Future.any([
      AdHelper.requestAd(
        scene: AdvertisingScene.open,
        detailScene: AdvertisingDetailScene.coldOpen,
      ),
      Future.delayed(Duration(seconds: AdHelper.openAppWaitSeconds)),
    ]);
    if (await EventsInfoUtil.isFirstIn) {
      if (!adCompleter.isCompleted) {
        adCompleter.complete(false);
      }
    } else {
      _adStatusSubscription = AdHelper.adShowStatusStream.listen((adInfo) {
        if ((adInfo.realScene ?? adInfo.scene) == AdvertisingScene.open) {
          if (adInfo.showState == AdShowStatus.showing) {
            isProgressFinish.value = true;
          }
          if (adInfo.showState == AdShowStatus.dismissed) {
            if (!adCompleter.isCompleted) {
              adCompleter.complete(true);
              _adStatusSubscription?.cancel();
            }
          }
        }
      });
      bool? showed = await AdvertisingDisplayCoordinator.showScene(
        scene: AdvertisingScene.open,
        detailScene: AdvertisingDetailScene.coldOpen,
      );
      Get.log(
        "Open ad show:$showed ${DateTime.now().difference(startTime).inSeconds}s",
      );
      if (showed != true) {
        if (!adCompleter.isCompleted) {
          adCompleter.complete(false);
          _adStatusSubscription?.cancel();
        }
      }
    }
    return adCompleter.future;
  }
}
