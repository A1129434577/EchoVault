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
    GlobalKey selectedKeyLocal = GlobalKey();
    ScrollController scrollControllerLocal = ScrollController();

    bool isAllVideoLocal = false;
    List<FileInfo> entries = records.whereType<FileInfo>().toList();
    if (entries.length == records.length) {
      isAllVideoLocal = entries
          .where((e) => e.type == MediaType.MUSIC_VIDEO_TYPE_ATV.name)
          .isEmpty;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double cellHeightLocal = 72, separatorHeightValueLocal = 4;
        if (isNeedPosition) {
          int activeIndex = -1;
          FileInfo? currentMediaInfoLocal =
              PlayerPlayback.instance.player.currentMediaInfo.value;
          if (currentMediaInfoLocal != null) {
            activeIndex = records.indexOf(currentMediaInfoLocal);
            if (activeIndex < 0) {
              activeIndex = records.indexWhere((e) {
                return e is FileInfo &&
                    e.fileId == currentMediaInfoLocal.fileId;
              });
            }
          }
          if (activeIndex > 0 && activeIndex < records.length) {
            if (constraints.maxHeight != double.infinity) {
              int onPageItemCountLocal =
                  constraints.maxHeight ~/
                  (cellHeightLocal + separatorHeightValueLocal);
              int positionIndexLocal = min(
                activeIndex,
                records.length - onPageItemCountLocal,
              );
              Future.delayed(Duration(milliseconds: 300), () {
                scrollControllerLocal.animateTo(
                  positionIndexLocal *
                      (cellHeightLocal + separatorHeightValueLocal),
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              });
            } else {
              Future.delayed(Duration(milliseconds: 100), () {
                if (selectedKeyLocal.currentContext != null) {
                  Scrollable.ensureVisible(selectedKeyLocal.currentContext!);
                }
              });
            }
          }
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: records.length,
          controller: scrollControllerLocal,
          padding: padding,
          separatorBuilder: (context, index) {
            return SizedBox(height: separatorHeightValueLocal);
          },
          itemBuilder: (context, index) {
            dynamic entry = records[index];
            return ValueListenableBuilder(
              valueListenable: PlayerPlayback.instance.player.currentMediaInfo,
              builder:
                  (
                    BuildContext context,
                    FileInfo? currentMediaInfo,
                    Widget? child,
                  ) {
                    int activeIndex = -1;
                    if (currentMediaInfo != null) {
                      activeIndex = records.indexOf(currentMediaInfo);
                      if (activeIndex < 0) {
                        activeIndex = records.indexWhere((e) {
                          return e is FileInfo &&
                              e.fileId == currentMediaInfo.fileId;
                        });
                      }
                    }

                    Widget nestedEntry = SizedBox();
                    if (entry is FileInfo) {
                      nestedEntry = GestureDetector(
                        onTap: () {
                          if (onFileCellTap == null) {
                            PlaybackNavigator.toPlay(
                              mediaQueue: records
                                  .whereType<FileInfo>()
                                  .toList(),
                              mediaEntry: entry,
                            );
                          } else {
                            onFileCellTap!.call(entry);
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                        child: MediaCell(
                          mediaDetails: entry,
                          isVideo: isAllVideoLocal,
                        ),
                      );
                    } else if (entry is PerformerDetails) {
                      nestedEntry = PerformerListCell(
                        performerDetails: entry,
                        action: Assets.images.common.optionsMuted.image(),
                      );
                    } else if (entry is MediaCollection) {
                      nestedEntry = CollectionListCell(
                        mediaCollection: entry,
                        showMoreAction: true,
                        action: Assets.images.common.optionsMuted.image(
                          width: 24,
                        ),
                      );
                    }

                    return Container(
                      height: cellHeightLocal,
                      key: index == activeIndex ? selectedKeyLocal : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: index == activeIndex ? Color(0xffEFF6FE) : null,
                      child: nestedEntry,
                    );
                  },
            );
          },
        );
      },
    );
  }
}
