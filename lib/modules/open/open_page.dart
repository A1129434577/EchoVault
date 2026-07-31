
import 'dart:async';

import 'package:ad/ad.dart';
import 'package:echo_vault/src/features/home/echo_vault_home.dart';
import 'package:echo_vault/src/services/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/open/controllers/open_controller.dart';
import 'package:echo_vault/modules/tab_page.dart';
import 'package:echo_vault/widgets/bg_container.dart';

class OpenPage extends StatefulWidget {
  const OpenPage({super.key});

  @override
  State<OpenPage> createState() => _OpenPageState();
}

class _OpenPageState extends State<OpenPage> {
  final OpenController _openController = OpenController.instance;


  @override
  void initState() {
    super.initState();
    prepareData();
  }

  Future prepareData() async {
    _openController.queryModules();
    int adStartTime = DateTime.now().millisecondsSinceEpoch;
    bool success = await _openController.loadAndShowAd();
    int adEndTime = DateTime.now().millisecondsSinceEpoch;
    //广告只要显示成功，关闭广告后必定需要进入主页
    //广告展示失败，并且花费时间比较少，如果cloak未请求成功可以继续用剩下的时间等待
    if(success != true){
      int adSeconds = ((adEndTime-adStartTime)/1000).toInt();
      if(adSeconds<(AdHelper.openAppWaitSeconds*0.5)){
        await Future.any([
          _openController.modulesCompleter.future,
          Future.delayed(Duration(seconds: AdHelper.openAppWaitSeconds-adSeconds)),
        ]);
      }
      _openController.isProgressFinish.value = true;
    }

    toHome();
  }



  Future toHome() async {
    if(_openController.isModulesUsable.value == true){
      Get.offAll(TabPage());
    }else{
      Get.offAll(EchoVaultHome(service: FlutterAudioService()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BgContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(flex: 2),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: Assets.images.brand.appLogo.image(),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'NocturneBox',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          Spacer(flex: 3),
          Column(
            children: [
              Text(
                'Resource loading…',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 15),
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(seconds: AdHelper.openAppWaitSeconds),
                builder: (context, double value, widget) {
                  return FractionallySizedBox(
                    widthFactor: 0.4,
                    child: ValueListenableBuilder(
                      valueListenable: _openController.isProgressFinish,
                      builder: (BuildContext context, bool isProgressFinish, Widget? child) {
                        return LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(2),
                          value: isProgressFinish?1:value,
                          backgroundColor: Color(0xFF5DE2C5).withAlpha((255*0.24).round()),
                          valueColor: AlwaysStoppedAnimation(
                            Color(0xFF5DE2C5),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          Spacer(flex: 1),
        ],
      ),
    );
  }
}
