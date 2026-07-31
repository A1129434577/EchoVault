import 'dart:io';

import 'package:echo_vault/modules/settings/user_feedback_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' hide FileInfo;
import 'package:player_base/player_base.dart';
import 'package:echo_vault/alerts/confirm_alert.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SettingController with ChangeNotifier {
  ValueNotifier<int> cacheSize = ValueNotifier(0);
  ValueNotifier<String> version = ValueNotifier('');

  Future getCache() async {
    int imageCacheSize = await DefaultCacheManager().store.getCacheSize();
    Directory cacheFileDirectory = Directory(await FileInfo.filesCacheDirectoryPath);
    int fileCacheSize = 0;
    if(cacheFileDirectory.existsSync()) {
      List<FileSystemEntity> list = cacheFileDirectory.listSync(
          recursive: true, followLinks: false);
      for (FileSystemEntity entity in list) {
        fileCacheSize += (await entity.stat()).size;
      }
    }
    cacheSize.value = fileCacheSize+imageCacheSize;
  }

  Future cleanCache() async {
    await DefaultCacheManager().emptyCache();
    String fileCachePath = await FileInfo.filesCacheDirectoryPath;
    Directory fileCacheDirectory = Directory(fileCachePath);
    if(fileCacheDirectory.existsSync()) {
      fileCacheDirectory.deleteSync(recursive: true);
    }
  }

  Future getAppVersion() async {
    PackageInfo packageInfo = await  PackageInfo.fromPlatform();
    version.value = packageInfo.version;
  }
}

class SettingListView extends StatelessWidget {

  final SettingController controller;
  final ScrollPhysics? physics;
  const SettingListView({
    super.key,
    required this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    List<String> titleList = [
      'Feedback'.translate,
      'Clean cache'.translate,
    ];
    return VisibilityDetector(
      key: Key('$SettingListView'),
      onVisibilityChanged: (VisibilityInfo info) {
        if(info.visibleFraction == 1){
          controller.getCache();
        }
      },
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: titleList.length,
        physics: physics,
        separatorBuilder:(context, index){
          return SizedBox(height: 15);
        },
        itemBuilder: (context, index){
          String title = titleList[index];
          return GestureDetector(
            onTap: () async {
              if(title == 'Feedback'.translate) {
                Get.to(UserFeedbackPage());
              }
              else if(title == 'Clean cache'.translate){
                ConfirmAlert.show(
                    title: 'Cache clean'.translate,
                    message: 'This will delete temporary data and cannot be undone. This will not affect your personal files or settings.'.translate,
                    onConfirm: () async {
                      await controller.cleanCache();
                      controller.getCache();
                    }
                );
              }
            },
            child: Container(
              color: Colors.transparent,
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  title=='Clean cache'.translate?
                  ValueListenableBuilder(
                    valueListenable: controller.cacheSize,
                    builder: (BuildContext context, int cacheSize, Widget? child) {
                      return Text(
                        cacheSize.bitFormat(),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      );
                    },
                  ):
                  Assets.optionsIcon.image( width: 20,),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}