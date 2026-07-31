
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/add_to_playlist_sheet.dart';
import 'package:echo_vault/alerts/sheet_bg_widget.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/artist_detail_page.dart';
import 'package:echo_vault/parse/data_sync_util.dart';
import 'package:echo_vault/utils/toast_util.dart';
import 'package:echo_vault/widgets/file/favorite_file_widget.dart';
import 'package:echo_vault/widgets/file/save_file_widget.dart';

class FileActionsSheet extends StatelessWidget {
  static String routeName = '$FileActionsSheet';

  static final StreamController<String> _actionsController = StreamController.broadcast();
  static  Stream<String> get actionsStream => _actionsController.stream;

  static void show({required FileInfo fileInfo}){
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(name: routeName, arguments: fileInfo),
      builder: (context){
        return FileActionsSheet(fileInfo: fileInfo);
      },
    );
  }

  final FileInfo fileInfo;
  const FileActionsSheet({
    super.key,
    required this.fileInfo,
  });

  @override
  Widget build(BuildContext context) {
    List<String> titleList = [
      'Offline'.translate,
      'Add to Library'.translate,
      'Play next'.translate,
      'Add to queue'.translate,
      'Add to playlist'.translate,
    ];
    if(fileInfo.uid != null){
      titleList.add('Go to artist'.translate);
    }

    FavoriteFileController favoriteController = FavoriteFileController();
    DownloadFileController downloadController = DownloadFileController();

    return SheetBgWidget(
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
                            url: fileInfo.thumbnail,
                            radius: 2,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            fileInfo.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.topRight,
                  child: CupertinoButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    sizeStyle: CupertinoButtonSize.small,
                    padding: EdgeInsets.zero,
                    child: Assets.images.common.dismiss.image( width: 20),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 22),
          Container(
            height: 1,
            color: Color(0xff121212).withAlpha((255*0.05).round()),
          ),
          SizedBox(height: 22),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 12),
            physics: NeverScrollableScrollPhysics(),
            itemCount: titleList.length,
            separatorBuilder:(context, index){
              return SizedBox(height: 32);
            },
            itemBuilder: (context, index){
              String title = titleList[index];
              if(title == 'Offline'.translate){
                return GestureDetector(
                  onTap: (){
                    _actionsController.add(title);
                    downloadController.saveStateChange();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        SaveFileWidget(
                          fileInfo: fileInfo,
                          controller: downloadController,
                          icon: Assets.images.prompts.savePrompt.path,
                          selectedIcon: Assets.images.collection.savePromptActive.path,
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              else if(title == 'Add to Library'.translate){
                return GestureDetector(
                  onTap: (){
                    _actionsController.add(title);
                    favoriteController.favoriteStateChange();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        FavoriteFileWidget(
                          fileInfo: fileInfo,
                          controller: favoriteController,
                          icon: Assets.images.prompts.favoritePrompt.path,
                          selectedIcon: Assets.images.collection.favoritePromptActive.path,
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              else if(title == 'Play next'.translate){
                return GestureDetector(
                  onTap: (){
                    _actionsController.add(title);
                    PlayerPlayback.instance.insertNextPlayList([fileInfo]);
                    ToastUtil.showSuccess('Will play next.'.translate);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.playNextPrompt.image(),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              else if(title == 'Add to queue'.translate){
                return GestureDetector(
                  onTap: (){
                    _actionsController.add(title);
                    PlayerPlayback.instance.insertPlayList([fileInfo]);
                    ToastUtil.showSuccess('Added to queue.'.translate);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.queueAddPrompt.image(),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              else if(title == 'Add to playlist'.translate){
                return GestureDetector(
                  onTap: (){
                    _actionsController.add(title);
                    AddToPlaylistSheet.show(fileInfo: fileInfo);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.prompts.playlistAddPrompt.image(),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              else if(title == 'Go to artist'.translate){
                return GestureDetector(
                  onTap: () async {
                    _actionsController.add(title);
                    ArtistInfo artist = ArtistInfo(id: fileInfo.uid, name: fileInfo.userName??'');
                    await DataSyncUtil.syncArtist(artist);
                    ArtistDetailPageUtil.to(artistInfo: artist);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      spacing: 16,
                      children: [
                        Assets.images.common.userIcon.image(),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
              return SizedBox();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom+24)
        ],
      ),
    );
  }
}
