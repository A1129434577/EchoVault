import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/controllers/favorite_artist_controller.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/widgets/artist_list_cell.dart';
import 'package:echo_vault/modules/artist/widgets/favorite_artist_widget.dart';
import 'package:echo_vault/modules/find/controllers/find_controller.dart';
import 'package:echo_vault/modules/home/controllers/home_controller.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/modules/playlist/widgets/favorite_group_widget.dart';
import 'package:echo_vault/modules/playlist/widgets/playlist_list_cell.dart';
import 'package:echo_vault/widgets/common_button.dart';
import 'package:echo_vault/widgets/file/dynamic_list_view.dart';
import 'package:echo_vault/widgets/file/file_cell.dart';
import 'package:echo_vault/widgets/file/save_file_widget.dart';
import 'package:echo_vault/widgets/refresh_load_widget.dart';

class FindTopResultView extends StatelessWidget {
  final FindController controller;
  const FindTopResultView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshLoadWidget(
      onLoading: HomeController.instance.isYoutubeMusicEnable.value?null:() async {
        return controller.loadMoreYTData();
      },
      controller: controller.refreshController,
      child: ValueListenableBuilder(
        valueListenable: controller.resourceList,
        builder: (BuildContext context, List<FileGroup>? resourceList, Widget? child) {
          List<FileGroup> topResultList = resourceList?.where((fileGroup){
            return fileGroup.params==null;
          }).firstOrNull?.children.cast()??[];

          FileGroup? topCardGroup = topResultList.where((fileGroup){
            return fileGroup.type == null;
          }).firstOrNull;

          List children = topResultList.where((fileGroup){
            return fileGroup.type != null;
          }).firstOrNull?.children??[];

          return ListView.separated(
            itemCount: (topCardGroup!=null?1:0)+(children.isNotEmpty?1:0),
            separatorBuilder:(context, index){
              return SizedBox(height: 20);
            },
            itemBuilder: (context, index){
              if(topCardGroup != null && index==0){
                return _topPartCell(topCardGroup);
              }

              return DynamicListView(
                dataList: children,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _topPartCell(FileGroup topGroup){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: topGroup.children.length,
        separatorBuilder:(context, index){
          return SizedBox(height: 20);
        },
        itemBuilder: (context, index){
          final item = topGroup.children[index];
          Widget? actionButton;
          if(item is FileInfo) {
            final DownloadFileController downloadFileController = DownloadFileController();
            actionButton = CommonButton(
              onPressed: (){
                downloadFileController.saveStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: SaveFileWidget(
                fileInfo: item,
                icon: Assets.other.saveAccent.path,
                controller: downloadFileController,
              ),
              title: 'Offline'.translate,
            );
          }
          else if(item is ArtistInfo){
            final FavoriteArtistController artistController = FavoriteArtistController(artist: item);
            actionButton = CommonButton(
              onPressed: (){
                artistController.favoriteStateChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: FavoriteArtistWidget(
                artist: item,
                icon: Assets.other.favoriteAccent.path,
                controller: artistController,
              ),
              title: 'Like'.translate,
            );
          }
          else if(item is FileGroup) {
            final FavoriteGroupController groupController = FavoriteGroupController(fileGroup: item);
            actionButton = CommonButton(
              onPressed: (){
                groupController.infoChange();
              },
              fontSize: 16,
              isWhite: true,
              icon: FavoriteGroupWidget(
                fileGroup: item,
                icon: Assets.other.favoriteAccent.path,
                controller: groupController,
              ),
              title: 'Like'.translate,
            );
          }
          
          if(index == 0){
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56,
                  child: _getTopCell(item),
                ),
                SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: Row(
                    spacing: 22,
                    children: [
                      Expanded(
                        child: CommonButton(
                          onPressed: (){
                            List<FileGroup> topResultList = controller.resourceList.value?.where((fileGroup){
                              return fileGroup.params==null;
                            }).firstOrNull?.children.cast()??[];
                            List<FileInfo> fileList = [];
                            for(final fileGroup in topResultList) {
                              fileList.addAll(fileGroup.children.whereType<FileInfo>());
                            }
                            PlayHelper.toPlay(fileList: fileList);
                          },
                          fontSize: 16,
                          icon: Assets.other.playlistPlay.image(),
                          title: 'Play'.translate,
                        ),
                      ),
                      if(actionButton!=null) Expanded(
                        child: actionButton,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),
              ],
            );
          }
          
          return SizedBox(
            height: 56,
            child: _getTopCell(item),
          );
        },
      ),
    );
  }
  
  Widget _getTopCell(dynamic item){
    if(item is FileInfo) {
      return GestureDetector(
        onTap: (){
          List<FileGroup> topResultList = controller.resourceList.value?.where((fileGroup){
            return fileGroup.params==null;
          }).firstOrNull?.children.cast()??[];

          List<FileInfo>? fileList = topResultList.firstOrNull?.children.whereType<FileInfo>().toList();
          if(fileList != null) {
            PlayHelper.toPlay(fileList: fileList, fileInfo: item);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: FileCell(fileInfo: item),
      );
    }
    else if(item is ArtistInfo){
      return ArtistListCell(
        artistInfo: item,
        action: Assets.other.optionsMuted.image(),
      );
    }
    else if(item is FileGroup) {
      return PlaylistListCell(
        fileGroup: item,
        showMoreAction: true,
        action: Assets.other.optionsMuted.image( width: 24),
      );
    }
    return SizedBox();
  }
}
