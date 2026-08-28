import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/shared/dialogs/confirmation_dialog.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/shared/dialogs/panel_background_view.dart';
import 'package:echo_vault/core/state/bookmark_collection_state.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class CollectionOptionsPanel extends StatefulWidget {
  static String panelRoute = '$CollectionOptionsPanel';

  final MediaCollection musicCollection;
  const CollectionOptionsPanel({super.key, required this.musicCollection});

  @override
  State<CollectionOptionsPanel> createState() => _CollectionOptionsPanelState();

  static void show({required MediaCollection musicCollectionArg}) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(name: panelRoute),
      builder: (buildContext) {
        return CollectionOptionsPanel(musicCollection: musicCollectionArg);
      },
    );
  }
}

class _CollectionOptionsPanelState extends State<CollectionOptionsPanel> {
  late MediaCollection musicCollection = widget.musicCollection;

  List<String> titleList = ['Rename'.translate, 'Delete'.translate];
  List<AssetGenImage> iconList = [
    Assets.images.collection.listRename,
    Assets.images.collection.listDelete,
  ];

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    spacing: 12,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: NetworkImageWidget(
                          url: musicCollection.thumbnail,
                          radius: 2,
                        ),
                      ),
                      Text(
                        musicCollection.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
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
          SizedBox(height: 30),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 12),
            physics: NeverScrollableScrollPhysics(),
            itemCount: titleList.length,
            separatorBuilder: (context, index) {
              return SizedBox(height: 32);
            },
            itemBuilder: (context, index) {
              String displayTitle = titleList[index];

              return GestureDetector(
                onTap: () {
                  if (displayTitle == 'Rename'.translate) {
                    NewCollectionDialog.show(
                      musicCollectionArg: musicCollection,
                    ).then((e) {
                      setState(() {});
                    });
                  } else if (displayTitle == 'Delete'.translate) {
                    ConfirmationDialog.show(
                      displayTitle: 'Delete',
                      messageArg:
                          'Are you sure you want to delete this playlist?',
                      onConfirmArg: () {
                        BookmarkCollectionState(
                          mediaCollectionArg: musicCollection,
                        ).updateCollection();
                        MessageOverlay.presentSuccess(
                          'Playlist deleted.'.translate,
                        );
                        Navigator.pop(context);
                      },
                    );
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Row(
                  spacing: 12,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: iconList[index].image(width: 24),
                    ),
                    Text(displayTitle, style: TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}
