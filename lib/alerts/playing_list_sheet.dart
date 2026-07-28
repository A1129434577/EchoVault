import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/widgets/file/dynamic_list_view.dart';

class PlayingListSheet extends StatefulWidget {
  static String routeName = '$PlayingListSheet';

  static void show(){
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      routeSettings: RouteSettings(name: routeName),
      builder: (context){
        return PlayingListSheet();
      },
    );
  }

  const PlayingListSheet({
    super.key,
  });

  @override
  State<PlayingListSheet> createState() => _PlayingListSheetState();
}

class _PlayingListSheetState extends State<PlayingListSheet> {

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: PlayerPlayback.instance.showPlayFileList,
      builder: (BuildContext context, List<FileInfo> showPlayFileList, Widget? child) {
        return SizedBox(
          height: MediaQuery.of(context).size.height/2,
          child: Column(
            spacing: 5,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 50,
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xffDFEBF7),
                      Colors.white,
                      // Color(0xffFAFAFA),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'Playlist'.translate}(${showPlayFileList.length})',
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
                      child: Image.asset(Assets.assetsAlertClose, height: 24),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: DynamicListView(
                  dataList: showPlayFileList,
                  isNeedPosition: true,
                  onFileCellTap: (fileInfo){
                    PlayerPlayback.instance.playAtIndex(showPlayFileList.indexOf(fileInfo));
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
