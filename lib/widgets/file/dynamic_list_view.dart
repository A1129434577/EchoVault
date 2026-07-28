import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/widgets/artist_list_cell.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/modules/playlist/widgets/playlist_list_cell.dart';
import 'package:echo_vault/parse/common_parse.dart';
import 'package:echo_vault/widgets/file/file_cell.dart';

class DynamicListView extends StatelessWidget {
  final List dataList;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ValueChanged<FileInfo>? onFileCellTap;
  //是否需要定位到正在播放
  final bool isNeedPosition;
  final EdgeInsets? padding;

  const DynamicListView({
    super.key,
    required this.dataList,
    this.shrinkWrap = false,
    this.physics,
    this.onFileCellTap,
    this.isNeedPosition = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    GlobalKey selectedKey = GlobalKey();
    ScrollController scrollController = ScrollController();

    bool isAllVideo = false;
    List<FileInfo> list = dataList.whereType<FileInfo>().toList();
    if(list.length == dataList.length){
      isAllVideo = list.where((e)=>e.type==FileType.MUSIC_VIDEO_TYPE_ATV.name).isEmpty;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double cellHeight = 72, separatorHeight = 4;
        if(isNeedPosition) {
          int selectedIndex=-1;
          FileInfo? currentMediaInfo = PlayerPlayback.instance.player.currentMediaInfo.value;
          if(currentMediaInfo != null){
            selectedIndex = dataList.indexOf(currentMediaInfo);
            if(selectedIndex < 0){
              selectedIndex = dataList.indexWhere((e){
                return e is FileInfo && e.fileId==currentMediaInfo.fileId;
              });
            }
          }
          if(selectedIndex>0 && selectedIndex<dataList.length){
            if(constraints.maxHeight!=double.infinity){
              int onPageItemCount = constraints.maxHeight ~/ (cellHeight+separatorHeight);
              int positionIndex = min(selectedIndex, dataList.length-onPageItemCount);
              Future.delayed(Duration(milliseconds: 300),(){
                scrollController.animateTo(
                  positionIndex*(cellHeight+separatorHeight),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              });
            }else{
              Future.delayed(Duration(milliseconds: 100),(){
                if(selectedKey.currentContext != null) {
                  Scrollable.ensureVisible(selectedKey.currentContext!);
                }
              });
            }
          }
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: dataList.length,
          controller: scrollController,
          padding: padding,
          separatorBuilder:(context, index){
            return SizedBox(height: separatorHeight);
          },
          itemBuilder: (context, index){
            dynamic item = dataList[index];
            return ValueListenableBuilder(
              valueListenable: PlayerPlayback.instance.player.currentMediaInfo,
              builder: (BuildContext context, FileInfo? currentMediaInfo, Widget? child) {
                int selectedIndex=-1;
                if(currentMediaInfo != null){
                  selectedIndex = dataList.indexOf(currentMediaInfo);
                  if(selectedIndex < 0){
                    selectedIndex = dataList.indexWhere((e){
                      return e is FileInfo && e.fileId==currentMediaInfo.fileId;
                    });
                  }
                }

                Widget child = SizedBox();
                if(item is FileInfo){
                  child = GestureDetector(
                    onTap: (){
                      if(onFileCellTap == null){
                        PlayHelper.toPlay(fileList: dataList.whereType<FileInfo>().toList(), fileInfo: item);
                      }else{
                        onFileCellTap!.call(item);
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: FileCell(fileInfo: item, isVideo: isAllVideo),
                  );
                }else if(item is ArtistInfo){
                  child = ArtistListCell(
                    artistInfo: item,
                    action: Image.asset(Assets.otherMoreGrey),
                  );
                }else if(item is FileGroup){
                  child = PlaylistListCell(
                    fileGroup: item,
                    showMoreAction: true,
                    action: Image.asset(Assets.otherMoreGrey, width: 24),
                  );
                }

                return Container(
                  height: cellHeight,
                  key: index==selectedIndex?selectedKey:null,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: index==selectedIndex?Color(0xffEFF6FE):null,
                  child: child,
                );
              },

            );
          },
        );
      },
    );
  }
}
