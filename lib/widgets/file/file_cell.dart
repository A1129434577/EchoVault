import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/alerts/file_actions_sheet.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/widgets/file/favorite_file_widget.dart';
import 'package:echo_vault/widgets/file/save_file_widget.dart';

class FileCell extends StatelessWidget {
  final FileInfo fileInfo;
  final bool isGrid;
  final bool isVideo;
  const FileCell({
    super.key,
    required this.fileInfo,
    this.isGrid = false,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    FavoriteFileController favoriteFileController = FavoriteFileController(fileInfo: fileInfo);
    return Row(
      children: [
        AspectRatio(
          aspectRatio: isVideo?98/56:1,
          child: NetworkImageWidget(
            url: fileInfo.thumbnail,
            radius: 6,
            defaultView: isVideo?
            Container(color: Color(0xffE8EDF4)):
            Image.asset(Assets.otherMusic),
          ),
        ),
        SizedBox(width: isGrid?10:12),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: favoriteFileController.notifier,
            builder: (BuildContext context, FileInfo? value, Widget? child) {
              return Column(
                spacing: isGrid?4:6,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileInfo.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  if(value?.isFavorite==1 || fileInfo.artist?.isNotEmpty==true)Row(
                    spacing: 2,
                    children: [
                      if(value?.isFavorite==1)SizedBox(
                        height: 16,
                        width: 16,
                        child: FavoriteFileWidget(
                          fileInfo: fileInfo,
                          controller: favoriteFileController,
                        ),
                      ),
                      if(fileInfo.artist?.isNotEmpty==true)Flexible(
                        child: Text(
                          fileInfo.artist!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff141414).withAlpha((255*0.5).round()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          height: 24,
          child: SaveFileWidget(fileInfo: fileInfo),
        ),
        SizedBox(width: isGrid?2:8),
        CupertinoButton(
          onPressed: (){
            FileActionsSheet.show(fileInfo: fileInfo);
          },
          sizeStyle: CupertinoButtonSize.small,
          padding: EdgeInsets.zero,
          child: Image.asset(Assets.otherLMore, height: 24),
        ),
      ],
    );
  }
}
