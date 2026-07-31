import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player_playback/player_playback.dart';
import 'package:echo_vault/core/persistence/media_collection_repository.dart';
import 'package:echo_vault/generated/assets.dart';
import 'package:echo_vault/core/models/performer_details.dart';
import 'package:echo_vault/features/performers/widgets/performer_list_cell.dart';
import 'package:echo_vault/features/playback/playback_screen.dart';
import 'package:echo_vault/features/collections/widgets/collection_list_cell.dart';
import 'package:echo_vault/core/parsing/shared_parser.dart';
import 'package:echo_vault/shared/widgets/media/media_cell.dart';

class AdaptiveListView extends StatelessWidget {
  final List records;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ValueChanged<FileInfo>? onFileCellTap;
  //是否需要定位到正在播放
  final bool isNeedPosition;
  final EdgeInsets? padding;

  const AdaptiveListView({
    super.key,
    required this.records,
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
    List<FileInfo> list = records.whereType<FileInfo>().toList();
    if (list.length == records.length) {
      isAllVideo = list
          .where((e) => e.type == MediaType.MUSIC_VIDEO_TYPE_ATV.name)
          .isEmpty;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double cellHeight = 72, separatorHeight = 4;
        if (isNeedPosition) {
          int selectedIndex = -1;
          FileInfo? currentMediaInfo =
              PlayerPlayback.instance.player.currentMediaInfo.value;
          if (currentMediaInfo != null) {
            selectedIndex = records.indexOf(currentMediaInfo);
            if (selectedIndex < 0) {
              selectedIndex = records.indexWhere((e) {
                return e is FileInfo && e.fileId == currentMediaInfo.fileId;
              });
            }
          }
          if (selectedIndex > 0 && selectedIndex < records.length) {
            if (constraints.maxHeight != double.infinity) {
              int onPageItemCount =
                  constraints.maxHeight ~/ (cellHeight + separatorHeight);
              int positionIndex = min(
                selectedIndex,
                records.length - onPageItemCount,
              );
              Future.delayed(Duration(milliseconds: 300), () {
                scrollController.animateTo(
                  positionIndex * (cellHeight + separatorHeight),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              });
            } else {
              Future.delayed(Duration(milliseconds: 100), () {
                if (selectedKey.currentContext != null) {
                  Scrollable.ensureVisible(selectedKey.currentContext!);
                }
              });
            }
          }
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: records.length,
          controller: scrollController,
          padding: padding,
          separatorBuilder: (context, index) {
            return SizedBox(height: separatorHeight);
          },
          itemBuilder: (context, index) {
            dynamic item = records[index];
            return ValueListenableBuilder(
              valueListenable: PlayerPlayback.instance.player.currentMediaInfo,
              builder:
                  (
                    BuildContext context,
                    FileInfo? currentMediaInfo,
                    Widget? child,
                  ) {
                    int selectedIndex = -1;
                    if (currentMediaInfo != null) {
                      selectedIndex = records.indexOf(currentMediaInfo);
                      if (selectedIndex < 0) {
                        selectedIndex = records.indexWhere((e) {
                          return e is FileInfo &&
                              e.fileId == currentMediaInfo.fileId;
                        });
                      }
                    }

                    Widget child = SizedBox();
                    if (item is FileInfo) {
                      child = GestureDetector(
                        onTap: () {
                          if (onFileCellTap == null) {
                            PlaybackNavigator.toPlay(
                              fileList: records.whereType<FileInfo>().toList(),
                              mediaDetails: item,
                            );
                          } else {
                            onFileCellTap!.call(item);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: MediaCell(
                          mediaDetails: item,
                          isVideo: isAllVideo,
                        ),
                      );
                    } else if (item is PerformerDetails) {
                      child = PerformerListCell(
                        performerDetails: item,
                        action: Assets.images.common.optionsMuted
                            .image(),
                      );
                    } else if (item is MediaCollection) {
                      child = CollectionListCell(
                        mediaCollection: item,
                        showMoreAction: true,
                        action: Assets.images.common.optionsMuted
                            .image(width: 24),
                      );
                    }

                    return Container(
                      height: cellHeight,
                      key: index == selectedIndex ? selectedKey : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: index == selectedIndex ? Color(0xffEFF6FE) : null,
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
