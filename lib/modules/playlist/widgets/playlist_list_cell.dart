import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/alerts/playlist_actions_sheet.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/playlist/playlist_detail_page.dart';

class PlaylistListCell extends StatelessWidget {
  final FileGroup fileGroup;
  final bool showMoreAction;
  final Widget? action;
  final VoidCallback? onTap;
  const PlaylistListCell({
    super.key,
    required this.fileGroup,
    this.showMoreAction = false,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(onTap != null){
          onTap!.call();
        }else{
          PlaylistDetailPageUtil.to(fileGroup: fileGroup);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            width: 60,
            height: 56,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xffD8E2F1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: NetworkImageWidget(
                    url: fileGroup.thumbnail,
                    radius: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileGroup.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  fileGroup.detail!=null?fileGroup.detail!:'${fileGroup.children.length} songs',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff141414).withAlpha((255*0.6).round())
                  ),
                ),
              ],
            ),
          ),
          if(showMoreAction)
            action??CupertinoButton(
              onPressed: (){
                PlaylistActionsSheet.show(musicGroup: fileGroup);
              },
              sizeStyle: CupertinoButtonSize.small,
              padding: EdgeInsets.zero,
              child: Assets.images.collection.listOptions.image( height: 24,),
            ),
        ],
      ),
    );
  }
}
