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

  ValueNotifier<bool?> isModulesUsable = ValueNotifier(null);

  final ValueNotifier<bool> isProgressFinish = ValueNotifier(false);
  StreamSubscription? _adStatusSubscription;

  static bool isNetworkUsable = true;

  late DateTime startTime;
  final Completer modulesCompleter = Completer();
  factory LaunchState() {
    return _instance;
  }
  LaunchState._() {
    listenNetwork();
  }
  static LaunchState get instance => _instance;
  Future listenNetwork() async {
    await Future.delayed(Duration(seconds: 5));
    //是否曾经是wifi
    bool? isLastWifiValueLocal;
    Connectivity connectivityLocal = Connectivity();
    connectivityLocal.onConnectivityChanged.listen((
      List<ConnectivityResult> connectivityResultArg,
    ) async {
      try {
        if (connectivityResultArg.contains(ConnectivityResult.mobile) ||
            connectivityResultArg.contains(ConnectivityResult.wifi) ||
            connectivityResultArg.contains(ConnectivityResult.ethernet) ||
            connectivityResultArg.contains(ConnectivityResult.vpn)) {
          isNetworkUsable = true;
          if (isModulesUsable.value == null) {
            if (modulesCompleter.isCompleted) {
              _queryModulesUsable(retryNumArg: 5);
            }
          }
          //如果曾经是wifi或者第一次检测到是流量，则提示
          if (isLastWifiValueLocal != false &&
              connectivityResultArg.contains(ConnectivityResult.wifi) ==
                  false) {
            isLastWifiValueLocal = false;
            MessageOverlay.showWarning(
              'Your Wi-Fi connection is weak. The app is now using your cellular data.'
                  .translate,
            );
          }
          if (connectivityResultArg.contains(ConnectivityResult.wifi) == true) {
            isLastWifiValueLocal = true;
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
    connectivityLocal.checkConnectivity();
  }

  Future<bool> loadAndShowAd() async {
    Completer<bool> adCompleterLocal = Completer();
    await Future.any([
      AdHelper.requestAd(
        scene: AdvertisingScene.open,
        detailScene: AdvertisingDetailScene.coldOpen,
      ),
      Future.delayed(Duration(seconds: AdHelper.openAppWaitSeconds)),
    ]);
    if (await EventsInfoUtil.isFirstIn) {
      if (!adCompleterLocal.isCompleted) {
        adCompleterLocal.complete(false);
      }
    } else {
      _adStatusSubscription = AdHelper.adShowStatusStream.listen((
        adInfoInputArg,
      ) {
        if ((adInfoInputArg.realScene ?? adInfoInputArg.scene) ==
            AdvertisingScene.open) {
          if (adInfoInputArg.showState == AdShowStatus.showing) {
            isProgressFinish.value = true;
          }
          if (adInfoInputArg.showState == AdShowStatus.dismissed) {
            if (!adCompleterLocal.isCompleted) {
              adCompleterLocal.complete(true);
              _adStatusSubscription?.cancel();
            }
          }
        }
      });
      bool? showedValueLocal = await AdvertisingDisplayCoordinator.showScene(
        scene: AdvertisingScene.open,
        detailScene: AdvertisingDetailScene.coldOpen,
      );
      Get.log(
        "Open ad show:$showedValueLocal ${DateTime.now().difference(startTime).inSeconds}s",
      );
      if (showedValueLocal != true) {
        if (!adCompleterLocal.isCompleted) {
          adCompleterLocal.complete(false);
          _adStatusSubscription?.cancel();
        }
      }
    }
    return adCompleterLocal.future;
  }

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

  Future _queryModulesUsable({int retryNumArg = 10}) async {
    String openVersionLocal = await RemoteFeatureSettings.modelCompleter.future;
    if (openVersionLocal.isEmpty) {
      openVersionLocal = '0.0.0';
    }
    openVersionLocal = openVersionLocal.replaceAll('.', '');
    String currentVersionStringLocal = await EventsInfoUtil.packageVersion();
    currentVersionStringLocal = currentVersionStringLocal.replaceAll('.', '');
    int deviationLocal =
        currentVersionStringLocal.length - openVersionLocal.length;
    if (deviationLocal < 0) {
      for (int offset = 0; offset < deviationLocal.abs(); offset++) {
        currentVersionStringLocal += '0';
      }
    } else if (deviationLocal > 0) {
      for (int offset = 0; offset < deviationLocal; offset++) {
        openVersionLocal += '0';
      }
    }
    if (int.parse(openVersionLocal) >= int.parse(currentVersionStringLocal)) {
      isModulesUsable.value = true;
      SharedPreferences spLocal = await SharedPreferences.getInstance();
      await spLocal.setBool(isModulesUsableKey, true);
    }

    if (isModulesUsable.value != true && retryNumArg > 0) {
      await Future.delayed(Duration(milliseconds: 500));
      retryNumArg--;
      await _queryModulesUsable(retryNumArg: retryNumArg);
    }
  }
}
