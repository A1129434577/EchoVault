import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/append_to_collection_panel.dart';
import 'package:echo_vault/shared/dialogs/panel_background_view.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/performer_detail_screen.dart';
import 'package:echo_vault/core/parsing/record_sync_helper.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';
import 'package:echo_vault/shared/widgets/media/bookmark_media_view.dart';
import 'package:echo_vault/shared/widgets/media/save_media_view.dart';

class MediaOptionsPanel extends StatelessWidget {
  static String routeName = '$MediaOptionsPanel';

  static final StreamController<String> _actionsController =
      StreamController.broadcast();

  final FileInfo mediaDetails;
  const MediaOptionsPanel({super.key, required this.mediaDetails});
  static Stream<String> get actionsStream => _actionsController.stream;

  @override
  Widget build(BuildContext context) {
    List<String> titleListLocal = [
      'Offline'.translate,
      'Add to Library'.translate,
      'Play next'.translate,
      'Add to queue'.translate,
      'Add to playlist'.translate,
    ];
    if (mediaDetails.uid != null) {
      titleListLocal.add('Go to artist'.translate);
    }

    BookmarkMediaState favoriteControllerLocal = BookmarkMediaState();
    TransferMediaState downloadControllerLocal = TransferMediaState();

    return PanelBackgroundView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 65,
            padding: EdgeInsetsGeometry.only(right: 5, top: 5),
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      spacing: 12,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: NetworkImageWidget(
                            url: mediaDetails.thumbnail,
                            radius: 2,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            mediaDetails.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Assets.images.common.dismiss.image(width: 20),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22),
          Container(
            height: 1,
            color: Color(0xff121212).withAlpha((255 * 0.05).round()),
          ),
          SizedBox(height: 22),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 12),
            physics: NeverScrollableScrollPhysics(),
            itemCount: titleListLocal.length,
            separatorBuilder: (context, index) {
              return SizedBox(height: 32);
            },
            itemBuilder: (context, index) {
              String displayTitle = titleListLocal[index];
              if (displayTitle == 'Offline'.translate) {
                return GestureDetector(
                  onTap: () {
                    _actionsController.add(displayTitle);
                    downloadControllerLocal.saveStateChange();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        SaveMediaView(
                          mediaDetails: mediaDetails,
                          controller: downloadControllerLocal,
                          icon: Assets.images.prompts.savePrompt.path,
                          selectedIcon:
                              Assets.images.collection.savePromptActive.path,
                        ),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              } else if (displayTitle == 'Add to Library'.translate) {
                return GestureDetector(
                  onTap: () {
                    _actionsController.add(displayTitle);
                    favoriteControllerLocal.favoriteStateChange();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        BookmarkMediaView(
                          mediaDetails: mediaDetails,
                          controller: favoriteControllerLocal,
                          icon: Assets.images.prompts.favoritePrompt.path,
                          selectedIcon: Assets
                              .images
                              .collection
                              .favoritePromptActive
                              .path,
                        ),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              } else if (displayTitle == 'Play next'.translate) {
                return GestureDetector(
                  onTap: () {
                    _actionsController.add(displayTitle);
                    PlayerPlayback.instance.insertNextPlayList([mediaDetails]);
                    MessageOverlay.showSuccess('Will play next.'.translate);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.playNextPrompt.image(),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              } else if (displayTitle == 'Add to queue'.translate) {
                return GestureDetector(
                  onTap: () {
                    _actionsController.add(displayTitle);
                    PlayerPlayback.instance.insertPlayList([mediaDetails]);
                    MessageOverlay.showSuccess('Added to queue.'.translate);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.queueAddPrompt.image(),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              } else if (displayTitle == 'Add to playlist'.translate) {
                return GestureDetector(
                  onTap: () {
                    _actionsController.add(displayTitle);
                    AppendToCollectionPanel.show(mediaEntry: mediaDetails);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.playlistAddPrompt.image(),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              } else if (displayTitle == 'Go to artist'.translate) {
                return GestureDetector(
                  onTap: () async {
                    _actionsController.add(displayTitle);
                    PerformerDetails artistLocal = PerformerDetails(
                      id: mediaDetails.uid,
                      name: mediaDetails.userName ?? '',
                    );
                    await RecordSyncHelper.syncArtist(artistLocal);
                    PerformerDetailScreenHelper.to(
                      performerProfile: artistLocal,
                    );
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.common.userIcon.image(),
                        Text(displayTitle, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  static void show({required FileInfo mediaEntry}) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(name: routeName, arguments: mediaEntry),
      builder: (buildContext) {
        return MediaOptionsPanel(mediaDetails: mediaEntry);
      },
    );
  }
}
