import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/widgets/file/file_cell.dart';

class FileHGridWidget extends StatelessWidget {
  final List<FileInfo> fileList;
  final ValueChanged<FileInfo>? onCellTap;
  const FileHGridWidget({
    super.key,
    required this.fileList,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (fileList.length>3)?(66*3+6*2):(fileList.length>2?66*2+6:66),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              mainAxisExtent: constraints.maxWidth*0.8,
              maxCrossAxisExtent: 66,
            ),
            itemCount: fileList.length,
            itemBuilder: (BuildContext ctx, int index) {
              FileInfo fileInfo = fileList[index];
              return ValueListenableBuilder(
                valueListenable: PlayerPlayback.instance.player.currentMediaInfo,
                builder: (BuildContext context, FileInfo? currentMediaInfo, Widget? child) {
                  int selectedIndex=-1;
                  if(currentMediaInfo?.fileId==fileInfo.fileId){
                    selectedIndex = index;
                  }
                  if(currentMediaInfo!=null && fileList.contains(currentMediaInfo)){
                    selectedIndex = fileList.indexOf(currentMediaInfo);
                  }
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: index==selectedIndex?Color(0xffEFF6FE):null,
                    child: GestureDetector(
                      onTap: (){
                        if(onCellTap == null){
                          PlayHelper.toPlay(fileList: fileList, fileInfo: fileInfo);
                        }else{
                          onCellTap!.call(fileInfo);
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: FileCell(fileInfo: fileInfo, isGrid: true),
                    ),
                  );
                },

              );
            },
          );
        },

      ),
    );
  }
}
