import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/ads/ads_show_manager.dart';
import 'package:echo_vault/utils/toast_util.dart';

class OpenController with ChangeNotifier {
  static const String isModulesUsableKey = 'isModulesUsableKey';

  static final OpenController _instance = OpenController._();
  static OpenController get instance => _instance;
  factory OpenController() {
    return _instance;
  }
  OpenController._(){
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
    connectivity.onConnectivityChanged.listen((List<ConnectivityResult> connectivityResult) async {
      try{
        if (connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.ethernet) ||
            connectivityResult.contains(ConnectivityResult.vpn)) {
          isNetworkUsable = true;
          if(isModulesUsable.value == null) {
            if(modulesCompleter.isCompleted) {
              _queryModulesUsable(retryNum: 5);
            }
          }
          //如果曾经是wifi或者第一次检测到是流量，则提示
          if (isLastWifi != false && connectivityResult.contains(ConnectivityResult.wifi) == false) {
            isLastWifi = false;
            ToastUtil.showWarning('Your Wi-Fi connection is weak. The app is now using your cellular data.'.translate);
          }
          if (connectivityResult.contains(ConnectivityResult.wifi) == true) {
            isLastWifi = true;
          }
        }else{
          isNetworkUsable = false;
          Future.delayed(Duration(seconds: 1),(){
            if(isNetworkUsable==false) {
              ToastUtil.showWarning(
                  'Network Unavailable,Please check your Wi-Fi or mobile data connection and try again.'
                      .translate);
            }
          });
        }
      }catch(_){}
    });
    ///开始检测网络环境
    connectivity.checkConnectivity();
  }

  late DateTime startTime;
  final Completer modulesCompleter = Completer();
  Future queryModules() async {
    startTime = DateTime.now();
    if(isModulesUsable.value == null){
      await _queryModulesUsable();
      modulesCompleter.complete();
    }else{
      modulesCompleter.complete();
    }
    return modulesCompleter.future;
  }

  Future _queryModulesUsable({int retryNum = 10}) async {
    String url = 'http://itunes.apple.com/cn/lookup?id=';
    dynamic result = await NetworkManager.instance.requestMethod(url: url, method: 'post');
    final results = result?['results'];
    if(results is List){
      result = results.firstOrNull;
    }
    if(result != null) {
      String? trackViewUrl = result?['trackViewUrl'];
      String currentVersionString = await EventsInfoUtil.packageVersion();
      currentVersionString = currentVersionString.replaceAll('.', '');
      String newVersionString = result?['version'] ?? '1.0.0';
      newVersionString = newVersionString.replaceAll('.', '');
      int deviation = currentVersionString.length - newVersionString.length;
      if (deviation < 0) {
        for (int i = 0; i < deviation.abs(); i++) {
          currentVersionString += '0';
        }
      } else if (deviation > 0) {
        for (int i = 0; i < deviation; i++) {
          newVersionString += '0';
        }
      }
      if (int.parse(newVersionString) >= int.parse(currentVersionString)) {
        isModulesUsable.value = true;
        SharedPreferences sp = await SharedPreferences.getInstance();
        await sp.setBool(isModulesUsableKey, true);
      }
    }
    if (kDebugMode) {
      isModulesUsable.value = true;
      SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setBool(isModulesUsableKey, true);
    }

    if (isModulesUsable.value != true && retryNum > 0) {
      await Future.delayed(Duration(milliseconds: 500));
      retryNum --;
      await _queryModulesUsable(retryNum: retryNum);
    }
  }


  Future<bool> loadAndShowAd() async {
    Completer<bool> adCompleter = Completer();
    await Future.any([
      AdHelper.requestAd(scene: AdsManagerScene.open, detailScene: AdsManagerDetailScene.coldOpen),
      Future.delayed(Duration(seconds: AdHelper.openAppWaitSeconds)),
    ]);
    if(await EventsInfoUtil.isFirstIn){
      if(!adCompleter.isCompleted){
        adCompleter.complete(false);
      }
    }else{
      _adStatusSubscription = AdHelper.adShowStatusStream.listen((adInfo){
        if((adInfo.realScene??adInfo.scene) == AdsManagerScene.open){
          if(adInfo.showState == AdShowStatus.showing) {
            isProgressFinish.value = true;
          }
          if(adInfo.showState == AdShowStatus.dismissed) {
            if (!adCompleter.isCompleted) {
              adCompleter.complete(true);
              _adStatusSubscription?.cancel();
            }
          }
        }
      });
      bool? showed = await AdsShowManager.showScene(scene: AdsManagerScene.open, detailScene: AdsManagerDetailScene.coldOpen);
      Get.log("Open ad show:$showed ${DateTime.now().difference(startTime).inSeconds}s");
      if(showed != true){
        if (!adCompleter.isCompleted) {
          adCompleter.complete(false);
          _adStatusSubscription?.cancel();
        }
      }
    }
    return adCompleter.future;
  }
}