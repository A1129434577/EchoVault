import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/alerts/confirm_alert.dart';
import 'package:echo_vault/alerts/create_playlist_alert.dart';
import 'package:echo_vault/alerts/sheet_bg_widget.dart';
import 'package:echo_vault/controllers/favorite_group_controller.dart';
import 'package:echo_vault/datebase/file_group_data_operate.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/utils/toast_util.dart';

class PlaylistActionsSheet extends StatefulWidget {
  static String routeName = '$PlaylistActionsSheet';

  static void show({required FileGroup musicGroup}){
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      routeSettings: RouteSettings(name: routeName),
      builder: (context){
        return PlaylistActionsSheet(musicGroup: musicGroup);
      },
    );
  }

  final FileGroup musicGroup;
  const PlaylistActionsSheet({
    super.key,
    required this.musicGroup,
  });

  @override
  State<PlaylistActionsSheet> createState() => _FileActionsSheetState();
}

class _FileActionsSheetState extends State<PlaylistActionsSheet> {
  late FileGroup musicGroup = widget.musicGroup;



  List<String> titleList = [
    'Rename'.translate,
    'Delete'.translate,
  ];
  List<AssetGenImage> iconList = [
    Assets.images.collection.listRename,
    Assets.images.collection.listDelete,
  ];

  @override
  Widget build(BuildContext context) {
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
                          url: musicGroup.thumbnail,
                          radius: 2,
                        ),
                      ),
                      Text(
                        musicGroup.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
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
          SizedBox(height: 30),
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

              return GestureDetector(
                onTap: () {
                  if(title == 'Rename'.translate){
                    CreatePlaylistAlert.show(musicGroup: musicGroup).then((e){
                      setState(() {});
                    });
                  }
                  else if(title == 'Delete'.translate){
                    ConfirmAlert.show(
                      title: 'Delete',
                      message: 'Confirm delete this playlist?',
                      onConfirm: (){
                        FavoriteGroupController(fileGroup: musicGroup).infoChange();
                        ToastUtil.showSuccess('Deleted.'.translate);
                        Navigator.pop(context);
                      }
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom+24)
        ],
      ),
    );
  }
}
