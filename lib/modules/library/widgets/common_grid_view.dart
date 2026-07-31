
import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/models/artist_info.dart';
import 'package:echo_vault/modules/artist/artist_detail_page.dart';
import 'package:echo_vault/modules/player/player_page.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';

///通用gridView,内容有可能是music|playlist|artist
class CommonGridView extends StatelessWidget {
  final List resourceList;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  const CommonGridView({
    super.key,
    this.resourceList = const [],
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth*0.9)/2;
        return GridView.builder(
          padding: padding,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 16,
            crossAxisCount: 2,
            crossAxisSpacing: constraints.maxWidth*0.1,
            mainAxisExtent: itemWidth/(130+10)*130+15,
          ),
          itemCount: resourceList.length,
          itemBuilder: (BuildContext ctx, int index) {
            final item = resourceList[index];
            return _CommonGridCell(
              item: item,
              onTap: (item is FileInfo)?(){
                List<FileInfo> fileList = resourceList.whereType<FileInfo>().toList();
                PlayHelper.toPlay(fileList: fileList, fileInfo: item);
              }:null,
            );
          },
        );
      },
    );
  }
}


class _CommonGridCell extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;
  const _CommonGridCell({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String thumbnail = '', title = '';
    String? subtitle;
    if(item is FileInfo){
      thumbnail = item.thumbnail;
      title = item.name;
      subtitle = item.artist;
    }else if(item is FileGroup){
      thumbnail = item.thumbnail;
      title = item.displayName;
      subtitle = item.detail;
    }else if(item is ArtistInfo){
      thumbnail = item.thumbnail;
      title = item.name;
      subtitle = item.desc;
    }
    return GestureDetector(
      onTap: (){
        if(onTap != null){
          onTap?.call();
        }else{
          if(item is FileGroup){
            PlaylistDetailPageUtil.to(fileGroup: item);
          }else if(item is ArtistInfo){
            ArtistDetailPageUtil.to(artistInfo: item);
          }
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: (130+10)/130,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xffD8E2F1),
                        borderRadius: BorderRadius.circular(6)
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: NetworkImageWidget(
                    radius: 10,
                    url: thumbnail,
                    fit: BoxFit.fill,
                    defaultView: Assets.other.albumPlaceholder.image( fit: BoxFit.fill),
                  ),
                ),
              ],
            ),
          ),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          if(subtitle!=null) Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xff141414).withAlpha((255*0.5).round()),
            ),
          ),
        ],
      ),
    );
  }
}