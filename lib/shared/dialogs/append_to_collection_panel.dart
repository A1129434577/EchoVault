import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/shared/dialogs/new_collection_dialog.dart';
import 'package:echo_vault/shared/dialogs/panel_background_view.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/features/catalog/controllers/catalog_state.dart';
import 'package:echo_vault/features/collections/widgets/collection_list_cell.dart';
import 'package:echo_vault/core/utilities/message_overlay.dart';

class AppendToCollectionPanel extends StatefulWidget {
  static String panelRoute = '$AppendToCollectionPanel';

  final FileInfo mediaDetails;
  const AppendToCollectionPanel({super.key, required this.mediaDetails});

  @override
  State<AppendToCollectionPanel> createState() =>
      _AppendToCollectionPanelState();

  static show({required FileInfo mediaEntry}) {
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      routeSettings: RouteSettings(name: panelRoute),
      builder: (buildContext) {
        return AppendToCollectionPanel(mediaDetails: mediaEntry);
      },
    );
  }
}

class _AppendToCollectionPanelState extends State<AppendToCollectionPanel> {
  late final FileInfo _fileInfo = widget.mediaDetails;

  @override
  Widget build(BuildContext context) {
    return PanelBackgroundView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add to playlist', style: TextStyle(fontSize: 18)),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Assets.images.status.dialogDismiss.image(height: 24),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        NewCollectionDialog.show();
                      },
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          spacing: 12,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Assets.images.collection.playlistCreate
                                  .image(),
                            ),
                            Text(
                              'New playlist'.translate,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Flexible(
                      child: ValueListenableBuilder(
                        valueListenable: CatalogState.instance.mediaCollections,
                        builder:
                            (
                              BuildContext context,
                              List<MediaCollection> musicGroupList,
                              Widget? child,
                            ) {
                              List<MediaCollection> entries = musicGroupList
                                  .where(
                                    (e) =>
                                        e.id?.startsWith(
                                          NewCollectionDialog
                                              .generatedCollectionPrefix,
                                        ) ==
                                        true,
                                  )
                                  .toList();
                              return ListView.separated(
                                itemCount: entries.length,
                                shrinkWrap: true,
                                separatorBuilder: (context, index) {
                                  return SizedBox(height: 24);
                                },
                                itemBuilder: (context, index) {
                                  MediaCollection mediaCollectionLocal =
                                      entries[index];
                                  return CollectionListCell(
                                    mediaCollection: mediaCollectionLocal,
                                    onTap: () async {
                                      await CatalogState.instance
                                          .addFileInfoToPlaylist(
                                            _fileInfo,
                                            mediaCollectionLocal,
                                          );
                                      MessageOverlay.presentSuccess(
                                        'Added.'.translate,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                      ),
                    ),
                    SizedBox(
                      height: max(24, MediaQuery.of(context).padding.bottom),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
