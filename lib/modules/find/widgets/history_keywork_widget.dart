import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/ads/ads_manager.dart';
import 'package:echo_vault/alerts/confirm_alert.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/find/find_page.dart';
import 'package:echo_vault/modules/tab_page.dart';

class HistoryKeyworkController with ChangeNotifier {
  static const String historyKeywordKey = 'historyKeywordKey';

  ValueNotifier<List<String>> keywordList = ValueNotifier([]);

  late final ValueNotifier<AdInfo?> searchNatoAd = ValueNotifier(AdHelper.adSceneCacheInfo[scene]);

  StreamSubscription? _adLoadSubscription;
  late VoidCallback _mainTabIndexListener;

  AdScene scene = AdsManagerScene.searchNative;
  final String tag;
  HistoryKeyworkController({required this.tag}){
    if(tag==FindPage.homeTag) {
      scene = AdsManagerScene.searchNative1;
    }
    AdHelper.loadSceneAdIfNull(scene: scene, detailScene: AdsManagerDetailScene.search);
    _adLoadSubscription = AdHelper.adLoadStatusStream.listen((adInfo) {
      if(adInfo.scene == scene){
        if (adInfo.loadState == AdLoadStatus.loaded) {
          searchNatoAd.value = adInfo;
          searchNatoAd.notifyListeners();
        }
      }
    });
    _mainTabIndexListener = (){
      if(TabPage.currentTabIndex.value==2){
        queryHistoryKeywork();
        AdHelper.loadSceneAdIfNull(scene: scene, detailScene: AdsManagerDetailScene.search);
      }
    };
    TabPage.currentTabIndex.addListener(_mainTabIndexListener);
  }

  Future<List<String>> queryHistoryKeywork() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? listJsonString =  sp.getString(historyKeywordKey);
    List list = [];
    if(listJsonString != null){
      list = jsonDecode(listJsonString);
    }
    keywordList.value = list.cast();
    return keywordList.value;
  }

  Future saveHistoryKeywork(String keywork) async {
    List<String> list = await queryHistoryKeywork();
    if(list.contains(keywork)){
      list.remove(keywork);
    }
    list.insert(0, keywork);
    if(list.length>10){
      list.sublist(0, 10);
    }
    keywordList.value = list;
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.setString(historyKeywordKey, jsonEncode(list));
  }

  Future clearHistoryKeywork() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove(historyKeywordKey);
    queryHistoryKeywork();
  }

  @override
  void dispose() {
    _adLoadSubscription?.cancel();
    TabPage.currentTabIndex.removeListener(_mainTabIndexListener);
    super.dispose();
  }
}

class HistoryKeyworkWidget extends StatefulWidget {

  final ValueChanged<String>? onTap;
  final String tag;
  const HistoryKeyworkWidget({
    super.key,
    this.onTap,
    required this.tag,
  });

  @override
  State<HistoryKeyworkWidget> createState() => _HistoryKeyworkWidgetState();
}

class _HistoryKeyworkWidgetState extends State<HistoryKeyworkWidget> {

  late final HistoryKeyworkController controller = Get.find<HistoryKeyworkController>(tag: widget.tag);

  @override
  void initState() {
    super.initState();
    controller.queryHistoryKeywork();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History record'.translate,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            CupertinoButton(
              onPressed: (){
                ConfirmAlert.show(
                    title: 'Delete',
                    message: 'Confirm delete the history?',
                    onConfirm: () {
                      controller.clearHistoryKeywork();
                    }
                );
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Image.asset(Assets.otherHDelete, width: 24,),
            ),
          ],
        ),
        Container(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(),
          padding: EdgeInsets.symmetric(vertical: 18),
          constraints: BoxConstraints(
            maxHeight: 35*3+16*2+18*2,
          ),
          child: ValueListenableBuilder(
            valueListenable: controller.keywordList,
            builder: (BuildContext context, List<String> keywordList, Widget? child) {
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: keywordList.map((keyword){
                  return GestureDetector(
                    onTap: (){
                      widget.onTap?.call(keyword);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        keyword,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.searchNatoAd,
          builder: (BuildContext context, AdInfo? adInfo, Widget? child) {
            if(adInfo?.ad != null || adInfo?.adView != null){
              return Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.topCenter,
                child: AspectRatio(
                  aspectRatio: 300/250,
                  child: NativePartAdView(
                    adInfo: adInfo!,
                    onCloseButtonClick: (){
                      controller.searchNatoAd.value = null;
                      AdHelper.loadSceneAdIfNull(scene: controller.scene, detailScene: AdsManagerDetailScene.search);
                    },
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }
}