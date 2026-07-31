import 'dart:io';

import 'package:echo_vault/features/preferences/user_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' hide FileInfo;
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/dialogs/confirmation_dialog.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PreferenceListView extends StatelessWidget {
  final PreferenceState controller;
  final ScrollPhysics? physics;
  const PreferenceListView({super.key, required this.controller, this.physics});

  @override
  Widget build(BuildContext context) {
    List<String> titleListLocal = [
      'Feedback'.translate,
      'Clean cache'.translate,
    ];
    return VisibilityDetector(
      key: Key('$PreferenceListView'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 1) {
          controller.getCache();
        }
      },
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: titleListLocal.length,
        physics: physics,
        separatorBuilder: (context, index) {
          return SizedBox(height: 15);
        },
        itemBuilder: (context, index) {
          String displayTitle = titleListLocal[index];
          return GestureDetector(
            onTap: () async {
              if (displayTitle == 'Feedback'.translate) {
                Get.to(UserFeedbackScreen());
              } else if (displayTitle == 'Clean cache'.translate) {
                ConfirmationDialog.show(
                  displayTitle: 'Cache clean'.translate,
                  messageArg:
                      'This will delete temporary data and cannot be undone. This will not affect your personal files or settings.'
                          .translate,
                  onConfirmArg: () async {
                    await controller.cleanCache();
                    controller.getCache();
                  },
                );
              }
            },
            child: Container(
              color: Colors.transparent,
              height: 35,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(displayTitle, style: TextStyle(fontSize: 14)),
                  displayTitle == 'Clean cache'.translate
                      ? ValueListenableBuilder(
                          valueListenable: controller.cacheSize,
                          builder:
                              (
                                BuildContext context,
                                int cacheSize,
                                Widget? child,
                              ) {
                                return Text(
                                  cacheSize.bitFormat(),
                                  style: TextStyle(fontSize: 14),
                                );
                              },
                        )
                      : Assets.images.shell.optionsIcon.image(width: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PreferenceState with ChangeNotifier {
  ValueNotifier<int> cacheSize = ValueNotifier(0);
  ValueNotifier<String> version = ValueNotifier('');

  Future cleanCache() async {
    await DefaultCacheManager().emptyCache();
    String fileCachePathLocal = await FileInfo.filesCacheDirectoryPath;
    Directory fileCacheDirectoryLocal = Directory(fileCachePathLocal);
    if (fileCacheDirectoryLocal.existsSync()) {
      fileCacheDirectoryLocal.deleteSync(recursive: true);
    }
  }

  Future getAppVersion() async {
    PackageInfo packageInfoLocal = await PackageInfo.fromPlatform();
    version.value = packageInfoLocal.version;
  }

  Future getCache() async {
    int imageCacheSizeLocal = await DefaultCacheManager().store.getCacheSize();
    Directory cacheFileDirectoryLocal = Directory(
      await FileInfo.filesCacheDirectoryPath,
    );
    int fileCacheSizeLocal = 0;
    if (cacheFileDirectoryLocal.existsSync()) {
      List<FileSystemEntity> entries = cacheFileDirectoryLocal.listSync(
        recursive: true,
        followLinks: false,
      );
      for (FileSystemEntity entity in entries) {
        fileCacheSizeLocal += (await entity.stat()).size;
      }
    }
    cacheSize.value = fileCacheSizeLocal + imageCacheSizeLocal;
  }
}
