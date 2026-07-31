import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/alerts/sheet_bg_widget.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/library/controllers/library_controller.dart';
import 'package:echo_vault/modules/playlist/widgets/playlist_list_cell.dart';
import 'package:echo_vault/utils/toast_util.dart';

class AddToPlaylistSheet extends StatefulWidget {
  static String routeName = '$AddToPlaylistSheet';

  static show({required FileInfo fileInfo}){
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      routeSettings: RouteSettings(name: routeName),
      builder: (context){
        return AddToPlaylistSheet(fileInfo: fileInfo);
      },
    );
  }

  final FileInfo fileInfo;
  const AddToPlaylistSheet({
    super.key,
    required this.fileInfo,
  });

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  late final FileInfo _fileInfo = widget.fileInfo;

  @override
  Widget build(BuildContext context) {
    return SheetBgWidget(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height/2,
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
                  Text(
                    'Add to playlist',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  CupertinoButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Assets.images.status.dialogDismiss.image( height: 24),
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
                      onTap: (){
                        CreatePlaylistAlert.show();
                      },
                      child: SizedBox(
                        height: 56,
                        child: Row(
                          spacing: 12,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Assets.images.collection.playlistCreate.image(),
                            ),
                            Text(
                              'New playlist'.translate,
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Flexible(
                      child: ValueListenableBuilder(
                        valueListenable: LibraryController.instance.fileGroupList,
                        builder: (BuildContext context, List<FileGroup> musicGroupList, Widget? child) {
                          List<FileGroup> list = musicGroupList.where((e)=>e.id?.startsWith(CreatePlaylistAlert.createPlaylistNamePrefix)==true).toList();
                          return ListView.separated(
                            itemCount: list.length,
                            shrinkWrap: true,
                            separatorBuilder:(context, index){
                              return SizedBox(height: 24);
                            },
                            itemBuilder: (context, index){
                              FileGroup fileGroup = list[index];
                              return PlaylistListCell(
                                fileGroup: fileGroup,
                                onTap: () async {
                                  await LibraryController.instance.addFileInfoToPlaylist(_fileInfo, fileGroup);
                                  ToastUtil.showSuccess('Added.'.translate);
                                },
                              );
                            },
                          );
                        },

                      ),
                    ),
                    SizedBox(height: max(24, MediaQuery.of(context).padding.bottom)),
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
