import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/controllers/download_file_controller.dart';
import 'package:echo_vault/controllers/favorite_file_controller.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/modules/player/player_page.dart';

class VideoPartGridWidget extends StatelessWidget {
  final List<FileInfo> fileList;
  const VideoPartGridWidget({
    super.key,
    required this.fileList,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth-12)/4*3;
        double aspectRatio = 248/140;
        return SizedBox(
          height: itemWidth/aspectRatio+35,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 12,
              mainAxisExtent: itemWidth,
              crossAxisCount: 1,
            ),
            itemCount: fileList.length,
            itemBuilder: (BuildContext ctx, int index) {
              FileInfo fileInfo = fileList[index];
              return GestureDetector(
                onTap: (){
                  PlayHelper.toPlay(fileList: fileList, fileInfo: fileInfo);
                },
                behavior: HitTestBehavior.translucent,
                child: _VideoGridCell(fileInfo: fileInfo),
              );
            },
          ),
        );
      },

    );
  }
}

class _VideoGridCell extends StatelessWidget {
  final FileInfo fileInfo;
  const _VideoGridCell({
    super.key,
    required this.fileInfo,
  });

  @override
  Widget build(BuildContext context) {
    FavoriteFileController favoriteFileController = FavoriteFileController(fileInfo: fileInfo);
    DownloadFileController downloadController = DownloadFileController();
    downloadController.fileInfoNotifier.value = fileInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 248/140,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xffE8EDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: NetworkImageWidget(
                  url: fileInfo.thumbnail,
                ),
              ),
              Center(
                child: Assets.images.media.overlayPlay.image( width: 38),
              ),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: favoriteFileController.notifier,
          builder: (BuildContext context, FileInfo? value, Widget? child) {
            return ValueListenableBuilder(
              valueListenable: favoriteFileController.notifier,
              builder: (BuildContext context, FileInfo? value, Widget? child) {
                return Text(
                  fileInfo.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                );
              },
            );
          },
        ),
        if(fileInfo.artist!=null) Text(
          fileInfo.artist!,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Color(0xff595959),
          ),
        )
      ],
    );
  }
}

