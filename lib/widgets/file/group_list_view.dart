import 'package:flutter/cupertino.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/home/group_more_page.dart';
import 'package:echo_vault/modules/artist/widgets/artist_part_grid_widget.dart';
import 'package:echo_vault/widgets/file/dynamic_list_view.dart';
import 'package:echo_vault/widgets/file/file_h_grid_widget.dart';
import 'package:echo_vault/widgets/file/video_part_grid_widget.dart';
import 'package:echo_vault/modules/playlist/widgets/playlist_part_grid_widget.dart';
import 'package:echo_vault/widgets/section_title_widget.dart';

class GroupListView extends StatelessWidget {
  final List<FileGroup> fileGroupList;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const GroupListView({
    super.key,
    this.fileGroupList = const [],
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      itemCount: fileGroupList.length,
      physics: physics,
      controller: controller,
      padding: padding,
      separatorBuilder:(context, index){
        return SizedBox(height: 18);
      },
      itemBuilder: (context, index){
        FileGroup fileGroup = fileGroupList[index];

        return Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(fileGroup.type!=null && fileGroup.name.isNotEmpty)Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SectionTitleWidget(
                title: fileGroup.name,
                onTap: fileGroup.id!=null?(){
                  Get.to(
                    GroupMorePage(fileGroup: fileGroup),
                    arguments: fileGroup,
                    preventDuplicates: false,
                  );
                }:null,
              ),
            ),
            if(fileGroup.type==FileGroupShowType.listMusic || fileGroup.type==null)
              DynamicListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                dataList: fileGroup.children.cast<FileInfo>(),
              ),
            if(fileGroup.type==FileGroupShowType.responsiveListMusic)
              FileHGridWidget(fileList: fileGroup.children.cast<FileInfo>()),
            if(fileGroup.type==FileGroupShowType.twoRowVideo)
              VideoPartGridWidget(fileList: fileGroup.children.cast<FileInfo>()),
            if(fileGroup.type==FileGroupShowType.twoRowArtist)
              ArtistPartGridWidget(artistList: fileGroup.children.cast<ArtistInfo>()),
            if(fileGroup.type==FileGroupShowType.twoRowPlaylist)
              PlaylistPartGridWidget(playlistList: fileGroup.children.cast<FileGroup>()),
          ],
        );
      },
    );
  }
}
