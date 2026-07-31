import 'package:flutter/cupertino.dart';
import 'package:player_base/player_base.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/performer_detail_screen.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/features/collections/collection_detail_screen.dart';

///通用gridView,内容有可能是music|playlist|artist
class SharedGridView extends StatelessWidget {
  final List resourceList;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;

  const SharedGridView({
    super.key,
    this.resourceList = const [],
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double itemWidth = (constraints.maxWidth * 0.9) / 2;
        return GridView.builder(
          padding: padding,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            mainAxisSpacing: 16,
            crossAxisCount: 2,
            crossAxisSpacing: constraints.maxWidth * 0.1,
            mainAxisExtent: itemWidth / (130 + 10) * 130 + 15,
          ),
          itemCount: resourceList.length,
          itemBuilder: (BuildContext ctx, int index) {
            final item = resourceList[index];
            return _SharedGridCell(
              item: item,
              onTap: (item is FileInfo)
                  ? () {
                      List<FileInfo> fileList = resourceList
                          .whereType<FileInfo>()
                          .toList();
                      PlaybackNavigator.toPlay(
                        fileList: fileList,
                        mediaDetails: item,
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}

class _SharedGridCell extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;
  const _SharedGridCell({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    String thumbnail = '', title = '';
    String? subtitle;
    if (item is FileInfo) {
      thumbnail = item.thumbnail;
      title = item.name;
      subtitle = item.artist;
    } else if (item is MediaCollection) {
      thumbnail = item.thumbnail;
      title = item.displayName;
      subtitle = item.detail;
    } else if (item is PerformerDetails) {
      thumbnail = item.thumbnail;
      title = item.name;
      subtitle = item.desc;
    }
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap?.call();
        } else {
          if (item is MediaCollection) {
            CollectionDetailScreenHelper.to(mediaCollection: item);
          } else if (item is PerformerDetails) {
            PerformerDetailScreenHelper.to(performerDetails: item);
          }
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: (130 + 10) / 130,
            child: Stack(
              children: [
                Positioned.fill(
                  top: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xffD8E2F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1,
                  child: NetworkImageWidget(
                    radius: 10,
                    url: thumbnail,
                    fit: BoxFit.fill,
                    defaultView: Assets.images.media.albumPlaceholder
                        .image(fit: BoxFit.fill),
                  ),
                ),
              ],
            ),
          ),
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xff141414).withAlpha((255 * 0.5).round()),
              ),
            ),
        ],
      ),
    );
  }
}
